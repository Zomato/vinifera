class NotificationWorker
  include Sidekiq::Worker
  sidekiq_options queue: :notification, retry: 2

  sidekiq_retries_exhausted do |msg, error|
    message = "Error in *NotificationWorker* \n error #{msg}: `#{error}`"
    SlackNotifier.new.notify(message, SlackNotifier::CHANNELS[:ERROR])
  end

  sidekiq_retry_in do |attempt, _|
    (30 * (attempt + 1)).seconds.to_i
  end

  def perform(message, channel = SlackNotifier::CHANNELS[:UPDATES])
    SlackNotifier.new.notify(message, channel)
  end

end