class TargetMonitorWorker
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker


  sidekiq_options queue: :monitor, retry: 5
  sidekiq_throttle(TargetMonitorThrottler.new.throttle_config)

  sidekiq_retries_exhausted do |msg, error|
    message = "Error in *TargetMonitorWorker* \n error #{msg}: `#{error}`"
    if [Octokit::TooManyRequests,Octokit::AbuseDetected].include?(error.class)
      TargetMonitorThrottler.new.throttle
    end

    SlackNotifier.new.notify(message, SlackNotifier::CHANNELS[:ERROR])
  end

  sidekiq_retry_in do |attempt, exception|
    case exception
    when Octokit::TooManyRequests
      TargetMonitorThrottler.new.throttle
      (5 * (attempt + 1)).minutes.to_i
    when Octokit::AbuseDetected
      TargetMonitorThrottler.new.throttle
      (10 * (attempt + 1)).minutes.to_i
    end
  end

  def perform(monitor_id)
    target_monitor = TargetMonitor.find(monitor_id)
    target_service = TargetService.new
    begin
      target_service.monitor(target_monitor)
    rescue TargetService::UnProcessableTarget => err
      target_monitor.disable!(err.message)
    rescue TargetService::RecoverableTarget => err
      target_monitor.update_meta_data(message: err.message)
    end

    if target_monitor.repeat
      TargetMonitorWorker.perform_in(target_monitor.repeat_interval.seconds, monitor_id)
      DataDogHelper::increment_key('target_monitor_worker_spawn_count')
    end

    target_monitor.record_last_run
  end
end