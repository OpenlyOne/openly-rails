class AddRepositoryToProject < ActiveRecord::Migration[5.2]
  def change
    add_reference :projects,
                  :repository,
                  foreign_key: { to_table: :vcs_repositories },
                  unique: true
    add_reference :projects,
                  :master_branch,
                  foreign_key: { to_table: :vcs_branches },
                  unique: true
  end
end
