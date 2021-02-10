module GithubService
  module Repo
    class Monitor
      def initialize(monitor)
        @monitor = monitor
      end

      def monitor
        target = @monitor.target
        return unless target.github? && target.repo?
        if target.meta_exists?("fork") && ENV['VINIFERA_ENABLE_FORK_SCANNING']
          ForkRepoMonitor.new(@monitor).monitor
        else
          SourceRepoMonitor.new(@monitor).monitor
        end
      end
    end
  end
end