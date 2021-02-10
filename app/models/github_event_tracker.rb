class GithubEventTracker < ApplicationRecord
  enum event_type: {push_event: 'PushEvent'}
end
