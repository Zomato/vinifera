class StrayCodeScannerWorker
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker

  sidekiq_throttle_as(:code_scanner_throttler)

  sidekiq_options queue: :code_scanner, retry: 2

  sidekiq_retries_exhausted do |msg, error|
    if [CodeScanner::ReaperKill, Docker::Error::DockerError].include?(error.class)
      CodeScanThrottler.new.throttle
    end
    message = "Error in *StrayCodeScannerWorker* \n error #{msg}: `#{error}`"
    SlackNotifier.new.notify(message, SlackNotifier::CHANNELS[:ERROR])
  end

  sidekiq_retry_in do |attempt, exception|
    case exception
    when CodeScanner::ReaperKill, Docker::Error::DockerError
      CodeScanThrottler.new.throttle
      (10 * (attempt + 1)).minutes.to_i
    end
  end

  def perform(url, opts = {})
    opts.deep_symbolize_keys!
    report = CodeScanner.new.scan(url, opts)
    ScanResultService::StrayCodeScanResultProcessor.new.process(report, url)
  end
end