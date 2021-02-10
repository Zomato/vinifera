module GithubService
  module Gist
    class Monitor
      def initialize(monitor)
        @github = Github.new
        @target_revision_service = TargetRevisionService.new
        @slack_notifier = SlackNotifier.new
        @monitor = monitor
      end

      def monitor
        target = @monitor.target
        return unless target.github? && target.gist?

        if @monitor.fresh?
          latest_commit = @github.gist_commits(target.external_id, {page_limit: 1}).first
          process_gist(target, latest_commit)
          @monitor.record_last_run
          return
        end

        gist_commits = @github.gist_commits(target.external_id)
        gist_commits.each do |gist_commit|
          process_gist_commit(target, gist_commit)
        end
      end

      private

      def process_gist(parent_gist, latest_commit)
        CodeScannerWorker.perform_async(parent_gist.id, @monitor.id)
        @target_revision_service.add_revision({target_id: parent_gist.id, external_id: parent_gist.external_id, revision_id: latest_commit.version, meta_data: latest_commit.commit.to_h})
      end

      def process_gist_commit(parent_gist, data)
        revision_id = data.version
        revision = @target_revision_service.revision_exists?(parent_gist.external_id, revision_id)
        return if revision

        discovery_message = ["Found new revision of  **#{revision_id}** of gist:  #{parent_gist.url}", "Revision url: #{[parent_gist.url, revision_id].join('/') } "].join("\n")
        @slack_notifier.notify(discovery_message,SlackNotifier::CHANNELS[:TARGET])

        CodeScannerWorker.perform_async(parent_gist.id, @monitor.id, {since: revision_id, from_commit: true})
        @target_revision_service.add_revision({target_id: parent_gist.id, external_id: parent_gist.external_id, revision_id: revision_id, meta_data: data.to_h.except(:user)})
      end
    end
  end
end