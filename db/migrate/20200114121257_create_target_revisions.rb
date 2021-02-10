class CreateTargetRevisions < ActiveRecord::Migration[6.0]
  def change
    create_table :target_revisions do |t|
      t.bigint :target_id, null: false
      t.string :external_id
      t.string :revision_id, null: false
      t.boolean :ignore,default: false
      t.jsonb :meta_data

      t.timestamps
    end
    add_index :target_revisions, :target_id
    add_index :target_revisions, :external_id
    add_index :target_revisions, :revision_id
    add_index :target_revisions, :ignore
    add_index :target_revisions, [:external_id,:revision_id], unique: true
  end
end
