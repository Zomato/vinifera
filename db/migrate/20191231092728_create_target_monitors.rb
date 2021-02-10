class CreateTargetMonitors < ActiveRecord::Migration[6.0]
  def change
    create_table :target_monitors do |t|
      t.bigint :target_id, null:false
      t.integer :repeat_interval
      t.boolean :repeat, default: false
      t.string :monitor_type, null: false
      t.jsonb :meta_data

      t.timestamps
    end
    add_index :target_monitors, :monitor_type
    add_index :target_monitors, :target_id
  end
end
