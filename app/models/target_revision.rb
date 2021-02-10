class TargetRevision < ApplicationRecord
  belongs_to :target

  def revision_timestamp
    meta_data['author']['date']
  end
end
