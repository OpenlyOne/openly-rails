class RenameExternalIdToRemoteId < ActiveRecord::Migration[5.2]
  def change
    tables_with_external_id_column =
      %i[vcs_archives vcs_file_backups vcs_file_snapshots vcs_file_thumbnails
         vcs_staged_files]

    tables_with_external_id_column.each do |table|
      rename_column table, :external_id, :remote_file_id
    end
  end
end
