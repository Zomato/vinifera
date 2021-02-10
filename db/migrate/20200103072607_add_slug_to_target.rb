class AddSlugToTarget < ActiveRecord::Migration[6.0]
  def change
    add_column :targets, :slug, :string
    add_column :targets, :status, :string
    add_column :targets, :external_id, :string, null: false
    add_index :targets, :slug
    add_index :targets, :status
    add_index :targets, :external_id
    add_index :targets, [:external_id,:provider,:target_type], unique: true
  end
end
