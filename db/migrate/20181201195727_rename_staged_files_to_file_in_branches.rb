class RenameStagedFilesToFileInBranches < ActiveRecord::Migration[5.2]
  def change
    rename_table :vcs_staged_files, :vcs_file_in_branches
    rename_index :vcs_file_in_branches,
                 :index_vcs_staged_files_on_root,
                 :index_vcs_file_in_branches_on_root
  end
end
