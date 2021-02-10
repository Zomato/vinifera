class TargetMonitorInstallWorker
  include Sidekiq::Worker
  sidekiq_options queue: :monitor_installer, retry: 2

  sidekiq_retries_exhausted do |msg, error|
    message = "Error in *TargetMonitorInstallWorker* \n error #{msg}: `#{error}`"
    SlackNotifier.new.notify(message, SlackNotifier::CHANNELS[:ERROR])
  end

  def perform(target_ids)
      target_monitor_installer =  TargetMonitorInstaller.new
      target_ids.each do |target_id|
        target = Target.find_by_id(target_id)
        DataDogHelper::increment_key('target_monitor_install_count')
        target_monitor_installer.install(target) if target.present?
      end
  end
end