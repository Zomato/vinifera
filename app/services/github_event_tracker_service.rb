class GithubEventTrackerService
  def register(events)
    events = [events] unless events.is_a? Array
    events.present? ? GithubEventTracker.insert_all(events, unique_by: :event_id) : []
  end

  def exists?(attrs)
    GithubEventTracker.exists?(attrs)
  end
end