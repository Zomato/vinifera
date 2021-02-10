class CodeScannerWorker
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker

  sidekiq_options queue: :code_scanner, retry: 2
  sidekiq_throttle_as(:code_scanner_throttler)

  sidekiq_retries_exhausted do |msg, error|
    if [CodeScanner::ReaperKill, Docker::Error::DockerError].include?(error.class)
      CodeScanThrottler.new.throttle
    end
    message = "Error in *CodeScannerWorker* \n error #{msg}: `#{error}`"
    SlackNotifier.new.notify(message, SlackNotifier::CHANNELS[:ERROR])
  end

  sidekiq_retry_in do |attempt, exception|
    case exception
    when CodeScanner::ReaperKill, Docker::Error::DockerError
      CodeScanThrottler.new.throttle
      (10 * (attempt + 1)).minutes.to_i
    end
  end

  def perform(target_id, monitor_id, opts = {})
    opts.deep_symbolize_keys!
    target = Target.find(target_id)
    monitor = TargetMonitor.find(monitor_id)
    report = CodeScanner.new.scan(target.url, opts)
    CodeScanResultProcessor.new(target, monitor).process(report) if report.present?
  end
end