# Modify the unique index on snapshots to use the new content ID column as a
# replacement for external_id and content_version
class ChangeUniqueConstraintVcsFileSnapshots < ActiveRecord::Migration[5.2]
  def up
    remove_index :vcs_file_snapshots,
                 name: :index_vcs_file_snapshots_on_metadata
    remove_index :vcs_file_snapshots,
                 name: :index_vcs_file_snapshots_on_metadata_without_parent
    add_index :vcs_file_snapshots,
              %i[file_record_id content_id file_record_parent_id name
                 mime_type],
              unique: true,
              name: :index_vcs_file_snapshots_on_metadata
    add_index :vcs_file_snapshots,
              %i[file_record_id content_id name mime_type],
              where: '(file_record_parent_id IS NULL)',
              unique: true,
              name: :index_vcs_file_snapshots_on_metadata_without_parent
  end

  def down
    remove_index :vcs_file_snapshots,
                 name: :index_vcs_file_snapshots_on_metadata
    remove_index :vcs_file_snapshots,
                 name: :index_vcs_file_snapshots_on_metadata_without_parent

    add_index :vcs_file_snapshots,
              %i[file_record_id external_id content_version mime_type name
                 file_record_parent_id],
              unique: true,
              name: :index_vcs_file_snapshots_on_metadata
    add_index :vcs_file_snapshots,
              %i[file_record_id external_id content_version mime_type name],
              where: '(file_record_parent_id IS NULL)',
              unique: true,
              name: :index_vcs_file_snapshots_on_metadata_without_parent
  end
end
