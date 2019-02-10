class AddUncapturedChangesCountToVcsBranches < ActiveRecord::Migration[5.2]
  def change
    add_column :vcs_branches, :uncaptured_changes_count, :integer,
               null: false, default: 0

    # set the correct count on existing branches
    VCS::Branch.reset_column_information
    VCS::Branch.find_each(&:update_uncaptured_changes_count)
  end
end
