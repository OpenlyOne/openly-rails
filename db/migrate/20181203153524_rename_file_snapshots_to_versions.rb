class RenameFileSnapshotsToVersions < ActiveRecord::Migration[5.2]
  def change
    rename_table :vcs_file_snapshots, :vcs_versions

    # Versions
    rename_index :vcs_versions,
                 :index_vcs_file_snapshots_on_metadata_without_parent,
                 :index_vcs_versions_on_metadata_without_parent
    rename_index :vcs_versions,
                 :index_vcs_file_snapshots_on_metadata,
                 :index_vcs_versions_on_metadata

    # FilesInBranches
    rename_column :vcs_file_in_branches,
                  :current_snapshot_id, :current_version_id
    rename_column :vcs_file_in_branches,
                  :committed_snapshot_id, :committed_version_id

    # CommittedFiles
    rename_column :vcs_committed_files, :file_snapshot_id, :version_id

    # FileBackups
    rename_column :vcs_file_backups, :file_snapshot_id, :file_version_id

    # FileDiffs
    rename_column :vcs_file_diffs, :new_snapshot_id, :new_version_id
    rename_column :vcs_file_diffs, :old_snapshot_id, :old_version_id
  end
end
