class TargetMonitorTransformer
  def transform(target_id, type, opts = {})
    {
      target_id: target_id,
      monitor_type: type,
      repeat: opts[:repeat],
      repeat_interval: opts[:repeat_interval].to_i,
      created_at: Time.zone.now,
      updated_at: Time.zone.now
    }
  end

  def transform_all(target_ids, type, opts = {})
    target_ids.map do |id|
      transform(id, type, opts)
    end
  end
end
