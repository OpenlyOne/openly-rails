# frozen_string_literal: true

class CreateVcsFileSnapshots < ActiveRecord::Migration[5.2]
  def change
    create_table :vcs_file_snapshots do |t|
      t.belongs_to :file_record, null: false,
                                 foreign_key: { to_table: :vcs_file_records }
      t.belongs_to :file_record_parent,
                   foreign_key: { to_table: :vcs_file_records }
      t.text :name, null: false
      t.text :content_version, null: false
      t.text :external_id, null: false
      t.string :mime_type, null: false
      t.belongs_to :thumbnail, foreign_key: { to_table: :vcs_file_thumbnails }

      t.index %i[file_record_id external_id content_version mime_type name
                 file_record_parent_id],
              name: 'index_vcs_file_snapshots_on_metadata',
              unique: true
      t.index %i[file_record_id external_id content_version mime_type name],
              name: 'index_vcs_file_snapshots_on_metadata_without_parent',
              unique: true,
              where: 'file_record_parent_id IS NULL'

      t.timestamps
    end
  end
end
