class GithubEventTrackerTransformer
  def transform_all(events, target_id)
    events.map do |event|
      transform(event, target_id)
    end
  end

  def transform(event, target_id)
    {
        target_id: target_id,
        event_id: event.id,
        meta_data: event.to_h,
        event_type: event.type,
        created_at: Time.zone.now,
        updated_at: Time.zone.now
    }
  end
end