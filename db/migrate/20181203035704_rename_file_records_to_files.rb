class RenameFileRecordsToFiles < ActiveRecord::Migration[5.2]
  def change
    rename_table :vcs_file_records, :vcs_files

    # FileSnapshots
    rename_column :vcs_file_snapshots, :file_record_id, :file_id
    rename_column :vcs_file_snapshots, :file_record_parent_id, :parent_id

    # FilesInBranches
    rename_column :vcs_file_in_branches, :file_record_id, :file_id
    rename_column :vcs_file_in_branches, :file_record_parent_id, :parent_id

    # Thumbnails
    rename_column :vcs_file_thumbnails, :file_record_id, :file_id
  end
end
