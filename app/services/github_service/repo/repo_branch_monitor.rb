module GithubService
  module Repo
    class RepoBranchMonitor
      SKIPPABLE_DIFF_STATUS = %w[identical behind].freeze

      def initialize(monitor, opts = {})
        @github = Github.new(skip_cache: true)
        @revision_service = TargetRevisionService.new
        @slack_notifier = SlackNotifier.new
        @monitor = monitor
        @monitor_opts = opts
      end

      def monitor(branch_name)
        target = @monitor.target
        latest_revision = @revision_service.latest_revision(target.external_id)
        upstream = @github.upstream_info(target.external_id.to_i)
        return unless upstream

        fork_owner = target.slug.split('/').first
        comparison_data = @github.compare_branches(upstream.full_name, branch_name, fork_owner, latest_revision.try(:revision_id) || branch_name)

        return unless comparison_data

        Rails.logger.info "[RepoBranchMonitor] Compare status - #{comparison_data.status} Monitor - #{@monitor.id} Target - #{target.id} - Branch - #{branch_name} Revision: #{latest_revision.try(:revision_id) || branch_name}"

        return if SKIPPABLE_DIFF_STATUS.include?(comparison_data.status)

        comparison_data.commits.each do |commit|
          process_commit(target, commit)
        end

        @monitor.record_last_run
      end

      private

      def process_commit(target, commit_data)
        commit_id = commit_data.sha
        revision = @revision_service.revision_exists?(target.external_id, commit_id)
        return if revision

        if @monitor_opts[:notify_discovery]
          discovery_message = ["Found new commit - *#{commit_id}* of repo :  #{target.url}", "Revision url: #{commit_data.html_url} "].join("\n")
          @slack_notifier.notify(discovery_message, SlackNotifier::CHANNELS[:TARGET])
        end
        CommitScannerWorker.perform_async(commit_data.url, target.id, @monitor.id)
        @revision_service.add_revision({target_id: target.id, external_id: target.external_id, revision_id: commit_id, meta_data: commit_data.commit.to_h})
      end
    end
  end
end