class SlackWebhookApi
  def initialize(webhook = nil, opts = {})
    webhook ||= ENV['SLACK_UPDATES_GROUP_URL']
    @notifier = Slack::Notifier.new(webhook || ENV['SLACK_UPDATES_GROUP_URL'])
  end

  def notify(message)
    @notifier.post(text: message)
  end

  alias_method :send_message, :notify
end