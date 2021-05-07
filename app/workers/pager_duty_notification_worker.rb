class PagerDutyNotificationWorker
  include Sidekiq::Worker
  sidekiq_options queue: :notification, retry: 2

  sidekiq_retries_exhausted do |msg, error|
    message = "Error in *PagerDutyNotificationWorker* \n error #{msg}: `#{error}`"
    SlackNotifier.new.notify(message, SlackNotifier::CHANNELS[:ERROR])
  end

  sidekiq_retry_in do |attempt, _|
    (30 * (attempt + 1)).seconds.to_i
  end

  def perform(model_klass, id)
    return if Rails.cache.exist?("pager_duty_alert_#{model_klass}_#{id}")

    model_details = model_klass.constantize.find(id)
    source = model_details.report_source
    incident_opts = {
      class: model_klass,
      source: source,
      summary: "#{model_klass} violation detected",
      timestamp: model_details.created_at,
      custom_details: model_details.attributes.except('meta_data').merge(source: source)
    }

    PagerDutyClient.new.create_incident(incident_opts)

    Rails.cache.write("pager_duty_alert_#{model_klass}_#{id}", expires_in: 30.minutes)
  end
end
