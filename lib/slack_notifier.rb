class SlackNotifier
  CHANNELS = {UPDATES: 'vinifera-updates',
              TARGET: 'vinifera-targets',
              USER_TRACKING: 'vinifera-user-tracking',
              VIOLATIONS: 'vinifera-violations',
              ERROR: 'vinifera-error'
  }.freeze

  def notify(message, channel = CHANNELS[:UPDATES])
    channel_webhook = channel_resolver(channel)
    SlackWebhookApi.new(channel_webhook).notify(message)
  end

  def self.async_notify(message,channel = CHANNELS[:UPDATES])
    NotificationWorker.perform_async(message, channel)
  end

  private

  def channel_resolver(channel)
    if channel == CHANNELS[:TARGET]
      ENV['SLACK_TARGETS_GROUP_URL']
    elsif channel == CHANNELS[:USER_TRACKING]
      ENV['SLACK_USER_TRACKING_GROUP_URL']
    elsif channel == CHANNELS[:VIOLATIONS]
      ENV['SLACK_VINIFERA_VIOLATION_GROUP_URL']
    elsif channel == CHANNELS[:ERROR]
      ENV['SLACK_ERROR_GROUP_URL']
    else
      ENV['SLACK_UPDATES_GROUP_URL']
    end
  end
end