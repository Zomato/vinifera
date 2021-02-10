module GithubService
  class PublicCommitProcessor
    def initialize
      @target_service = TargetService.new
      @slack_notifier = SlackNotifier.new
      @github_event_tracker_service = GithubEventTrackerService.new
      @transformer = GithubEventTrackerTransformer.new
    end

    def process(events, target)
      @target = target
      processed_events = events.each_with_object([]) do |event, processed_events|
        if @target_service.target_exists?(external_id: event.repo.id) && !(@target_service.fetch_target(external_id: event.repo.id)&.github_fork?)
          next
        end

        next if @github_event_tracker_service.exists?(event_id: event.id)

        process_repo_push(event)
        processed_events << event
      end
      return unless processed_events.present?

      transformed_events = @transformer.transform_all(processed_events, @target.id)
      @slack_notifier.notify("Found #{transformed_events.count} push commits for #{@target.slug}")
      @github_event_tracker_service.register(transformed_events)
    end

    private

    def process_repo_push(event)
      event.payload.commits.each do |commit|
        event_target = @target_service.fetch_target(external_id: event.repo.id)
        if event_target
          process_as_registered(event_target, commit)
        else
          process_as_stray(commit, "https://github.com/#{event.repo.name}.git")
        end
      end
    end

    def process_as_registered(event_target, commit)
      monitor = event_target.target_monitors.gitleaks.first
      if event_target.big_github_fork?
        @slack_notifier.notify("Repo commit found for Big fork found - #{event_target.url} - #{commit.url}")
        CommitScannerWorker.perform_async(commit.url, event_target.id, monitor.id)
      else
        @slack_notifier.notify("Repo commit found for normal fork found - #{event_target.url} - #{commit.url}")
        CodeScannerWorker.perform_async(event_target.id, monitor.id, { only_commit: true, commit_id: commit.sha })
      end
    end

    def process_as_stray(commit, url)
      opts = { only_commit: true, commit_id: commit.sha }
      @slack_notifier.notify("External Repo push Found for  #{url} \b commit id #{commit.sha} - #{@target.slug}")
      StrayCodeScannerWorker.perform_async(url, opts)
    end
  end
end