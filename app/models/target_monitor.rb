class TargetMonitor < ApplicationRecord
  DEFAULT_REPEAT_INTERVAL = 40.minutes

  belongs_to :target

  enum monitor_type: { gitleaks: 'gitleaks', user_monitor: 'user_monitor' }

  def record_last_run
    updated_meta_data = add_meta_data(last_run: Time.zone.now)
    update!(meta_data: updated_meta_data)
  end

  def fetch_meta_data(*keys)
    keys.map!(&:to_s)
    meta_data.nil? ? {} : meta_data.slice(*keys)
  end

  def update_meta_data(data)
    update(meta_data: add_meta_data(data))
  end

  def fresh?
    meta_data.try(:[], 'last_run').nil?
  end

  def disable!(reason = nil)
    updated_meta_data = add_meta_data(message: reason)
    update!(repeat: false, meta_data: updated_meta_data)
  end

  private

  def add_meta_data(data)
    (meta_data || {}).merge!(data)
  end
end
