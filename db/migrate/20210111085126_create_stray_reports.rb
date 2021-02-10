class CreateStrayReports < ActiveRecord::Migration[6.0]
  def change
    create_table :stray_reports do |t|
      t.string :url, null: false
      t.jsonb :meta_data

      t.timestamps
    end
    add_index :stray_reports, :url
  end
end
