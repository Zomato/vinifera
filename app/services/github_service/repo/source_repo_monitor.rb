module GithubService
  module Repo
    class SourceRepoMonitor
      REPORT_SPLIT_SIZE = 4

      def initialize(monitor)
        @github = Github.new
        @revision_service = TargetRevisionService.new
        @slack_notifier = SlackNotifier.new
        @monitor = monitor
      end

      def monitor
        target = @monitor.target

        if @monitor.fresh?
          latest_commit = @github.repo_commits(target.external_id.to_i, {page_limit: 1}).first
          process_repo(target, latest_commit)
          @monitor.record_last_run
          return
        end

        latest_revision = @revision_service.latest_revision(target.external_id)
        search_opts = latest_revision.present? ? {since: latest_revision.revision_timestamp} : {}
        repo_commits = @github.repo_commits(target.external_id.to_i, search_opts)

        repo_commits.each do |repo_commit|
          process_repo_commit(target, repo_commit)
        end
      end

      private

      def process_repo(parent_repo, latest_commit)
        CodeScannerWorker.perform_async(parent_repo.id, @monitor.id)
        @revision_service.add_revision({target_id: parent_repo.id, external_id: parent_repo.external_id, revision_id: latest_commit.sha, meta_data: latest_commit.commit.to_h})
      end

      def process_repo_commit(parent_repo, commit_data)
        commit_id = commit_data.sha
        revision = @revision_service.revision_exists?(parent_repo.external_id, commit_id)
        return if revision

        discovery_message = ["Found new commit - *#{commit_id}* of repo :  #{parent_repo.url}", "Revision url: #{commit_data.html_url} "].join("\n")
        @slack_notifier.notify(discovery_message, SlackNotifier::CHANNELS[:TARGET])
        CodeScannerWorker.perform_async(parent_repo.id, @monitor.id, {commit_id: commit_id, only_commit: true})
        @revision_service.add_revision({target_id: parent_repo.id, external_id: parent_repo.external_id, revision_id: commit_id, meta_data: commit_data.commit.to_h})
      end
    end
  end
end