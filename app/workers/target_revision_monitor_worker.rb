class TargetRevisionMonitorWorker
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker


  sidekiq_throttle_as(:code_scanner_throttler)

  sidekiq_options queue: :revision_monitor, retry: 5

  sidekiq_retries_exhausted do |msg, error|
    message = "Error in *TargetMonitorWorker* \n error #{msg}: `#{error}`"
    SlackNotifier.new.notify(message, SlackNotifier::CHANNELS[:ERROR])
  end

  sidekiq_retry_in do |attempt, exception|
    case exception
    when CodeScanner::ZombieScan
      CodeScanThrottler.new.throttle
      5.minutes
    when Docker::Error::DockerError
      CodeScanThrottler.new.throttle
      (15 * (attempt + 1)).minutes.to_i
    when Octokit::AbuseDetected
      (10 * (attempt + 1)).minutes.to_i
    end
  end

  def perform(monitor_id, branch_name)
    target_monitor = TargetMonitor.find(monitor_id)
    opts = jid ? {} : {notify_discovery: true} # Enable discovery only for sync jobs
    repo_branch_monitor = GithubService::Repo::RepoBranchMonitor.new(target_monitor, opts)
    repo_branch_monitor.monitor(branch_name)
    target_monitor.record_last_run
  end
end