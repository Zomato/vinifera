class CreateGithubEventTrackers < ActiveRecord::Migration[6.0]
  def change
    create_table :github_event_trackers do |t|
      t.bigint :target_id, null: false
      t.bigint :event_id, null: false
      t.string :event_type, null: false
      t.jsonb :meta_data

      t.timestamps
    end
    add_index :github_event_trackers, :target_id
    add_index :github_event_trackers, :event_id, unique: true
  end
end
