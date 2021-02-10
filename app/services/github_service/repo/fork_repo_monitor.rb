module GithubService
  module Repo
    class ForkRepoMonitor
      def initialize(monitor)
        @github = Github.new(skip_cache: true)
        @monitor = monitor
      end

      def monitor
        target = @monitor.target
        branches = @github.repo_branches(target.external_id.to_i)
        branches.each do |branch|
          process_branch(branch.name, target.big_github_fork?)
        end
        @monitor.record_last_run
      end

      private

      def process_branch(branch_name, big = true)
        return if big && !(ENV['VINIFERA_ENABLE_BIG_FORK_SCANNING'])

        TargetRevisionMonitorWorker.perform_async(@monitor.id, branch_name)
      end
    end
  end
end