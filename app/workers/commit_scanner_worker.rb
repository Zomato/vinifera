class CommitScannerWorker
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker

  sidekiq_throttle_as(:code_scanner_throttler)

  sidekiq_options queue: :code_scanner, retry: 2

  sidekiq_retries_exhausted do |msg, error|
    if [CodeScanner::ReaperKill, Docker::Error::DockerError].include?(error.class)
      CodeScanThrottler.new.throttle
    end
    message = "Error in *CommitScannerWorker* \n error #{msg}: `#{error}`"
    SlackNotifier.new.notify(message, SlackNotifier::CHANNELS[:ERROR])
  end

  sidekiq_retry_in do |attempt, exception|
    case exception
    when CodeScanner::ReaperKill, Docker::Error::DockerError
      CodeScanThrottler.new.throttle
      (10 * (attempt + 1)).minutes.to_i
    end
  end

  def perform(commit_url, target_id = nil, monitor_id = nil, opts = {})
    reports = GithubService::Commit::ContentProcessor.new.process(commit_url)
    target = target_id.nil? ? target_id : Target.find(target_id)
    monitor = monitor_id.nil? ? monitor_id : TargetMonitor.find(monitor_id)
    reports.each do |report|
      FileScanResultProcessor.new(target, monitor).process(report, commit_url)
    end
  end
end