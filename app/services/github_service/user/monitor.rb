module GithubService
  module User
    class Monitor
      def initialize(monitor)
        @github = Github.new
        @github_gist_syncer = GithubUserGistSyncer.new
        @github_repo_syncer = GithubUserRepoSyncer.new
        @github_activity_syncer = GithubUserActivitySyncer.new
        @monitor = monitor
      end

      def monitor
        target = @monitor.target
        monitor_last_run = @monitor.fetch_meta_data(:last_run)['last_run']
        return unless target.github? && target.user?

        @github_gist_syncer.sync_gists(target)
        @github_repo_syncer.sync_repos(target)
        @github_activity_syncer.sync_activity(target, monitor_last_run) if ENV['VINIFERA_SYNC_USER_ACTIVITY']
      end
    end
  end
end