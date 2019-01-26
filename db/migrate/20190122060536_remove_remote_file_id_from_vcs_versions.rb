class RemoveRemoteFileIdFromVcsVersions < ActiveRecord::Migration[5.2]
  def change
    remove_column :vcs_versions, :remote_file_id, :text, null: false
  end
end
