class CreateReports < ActiveRecord::Migration[6.0]
  def change
    create_table :reports do |t|
      t.bigint :target_id, null: false
      t.bigint :target_monitor_id
      t.binary :run_logs
      t.jsonb :meta_data

      t.timestamps
    end
    add_index :reports, :target_id
    add_index :reports, :target_monitor_id
  end
end
