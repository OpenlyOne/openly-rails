class AllowNullForRemoteFileIdFromFileInBranch < ActiveRecord::Migration[5.2]
  def change
    change_column_null :vcs_file_in_branches, :remote_file_id, true
  end
end
