class TargetMonitorUniqueMonitorId < ActiveRecord::Migration[6.0]
  def change
    remove_index :target_monitors, [:target_id]
    add_index :target_monitors, [:target_id,:monitor_type], unique: true
  end
end
