class StrayReport < ApplicationRecord
  after_create_commit -> { PagerDutyNotificationWorker.perform_async(self.class.name, self.id) }, if: -> { ENV['ENABLE_PAGER_DUTY_TRIGGER'] }

  def report_source
    self.url
  end
end
