class CreateTargets < ActiveRecord::Migration[6.0]
  def change
    create_table :targets do |t|
      t.string :url
      t.string :target_type
      t.string :provider
      t.jsonb :meta_data

      t.timestamps
    end
    add_index :targets, [:url,:target_type], unique: true
    add_index :targets, :provider
  end
end
