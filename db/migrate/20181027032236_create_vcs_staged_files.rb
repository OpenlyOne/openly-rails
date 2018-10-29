class CreateVcsStagedFiles < ActiveRecord::Migration[5.2]
  def change
    create_table :vcs_staged_files do |t|
      t.belongs_to :branch, null: false, foreign_key: { to_table: :vcs_branches }
      t.belongs_to :file_record, null: false, foreign_key: { to_table: :vcs_file_records }
      t.text :external_id, null: false
      t.belongs_to :file_record_parent, foreign_key: { to_table: :vcs_file_records }
      t.text :name
      t.text :content_version
      t.string :mime_type
      t.boolean :is_deleted, default: false, null: false
      t.belongs_to :current_snapshot
      t.belongs_to :committed_snapshot, foreign_key: { to_table: :vcs_file_snapshots }
      t.belongs_to :thumbnail, foreign_key: { to_table: :vcs_file_thumbnails }

      t.boolean :is_root, null: false, default: false

      # Can only have one instance of each file record per branch
      t.index %i[branch_id file_record_id], unique: true

      # Can only have one root file per branch
      t.index :branch_id,
              name: 'index_vcs_staged_files_on_root',
              unique: true,
              where: 'is_root IS TRUE'

      t.index %i[branch_id external_id], unique: true

      t.timestamps
    end
  end
end
