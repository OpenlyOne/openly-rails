class CreateVcsFileBackups < ActiveRecord::Migration[5.2]
  def change
    create_table :vcs_file_backups do |t|
      t.belongs_to :file_snapshot,
                   null: false, unique: true,
                   foreign_key: { to_table: :vcs_file_snapshots }
      t.text :external_id, null: false

      t.timestamps
    end
  end
end
