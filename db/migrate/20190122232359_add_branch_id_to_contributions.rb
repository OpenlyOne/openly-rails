class AddBranchIdToContributions < ActiveRecord::Migration[5.2]
  # Each contribution (pull request) belongs to a branch
  def change
    add_column :contributions, :branch_id, :bigint, null: false
    add_foreign_key :contributions, :vcs_branches, column: :branch_id
  end
end
