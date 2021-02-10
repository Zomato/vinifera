class TargetMonitorInstaller
  def initialize
    @transformer = TargetMonitorTransformer.new
    @slack_notifier = SlackNotifier.new
  end

  def install(target)
    monitor_type = monitor_type_resolver(target)
    repeat_interval = repeat_interval(target)
    transformed_request = @transformer.transform(target.id, monitor_type, {repeat: true, repeat_interval: repeat_interval})
    response = TargetMonitor.insert(transformed_request)
    response.pluck('id').each do |id|
      TargetMonitorWorker.perform_async(id)
    end
    notify_new_target(target)
  end

  private

  def notify_new_target(target)
    message = "Found new target - #{target.url}"
    @slack_notifier.notify(message, SlackNotifier::CHANNELS[:USER_TRACKING])
  end

  def repeat_interval(target)
    if target.github?
      github_scan_interval(target)
    else
      TargetMonitor::DEFAULT_REPEAT_INTERVAL
    end
  end

  def monitor_type_resolver(target)
    if target.user?
      TargetMonitor.monitor_types[:user_monitor]
    else
      TargetMonitor.monitor_types[:gitleaks]
    end
  end

  # TOD0: Refactor once services are broken up
  def github_scan_interval(target)
    if target.user?
      2.hours
    elsif target.big_github_fork?
      4.hours # Monitor big forks slowly
    else
      TargetMonitor::DEFAULT_REPEAT_INTERVAL
    end
  end
end