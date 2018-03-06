# frozen_string_literal: true

# Create table for FileResource::Snapshot
class CreateFileResourceSnapshots < ActiveRecord::Migration[5.1]
  def change
    create_table :file_resource_snapshots do |t|
      t.belongs_to :file_resource, null: false
      t.belongs_to :parent, null: true,
                            foreign_key: { to_table: :file_resources }
      t.text :name, null: false
      t.text :content_version, null: false
      t.text :external_id, null: false
      t.string :mime_type, null: false

      t.index %i[external_id content_version mime_type name parent_id],
              name: 'index_file_resource_snapshots_on_metadata',
              unique: true
      t.index %i[external_id content_version mime_type name],
              name: 'index_file_resource_snapshots_on_metadata_without_parent',
              unique: true,
              where: 'parent_id IS NULL'

      t.timestamps
    end
  end
end
