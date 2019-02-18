class DropAreContributionsEnabledFromProjects < ActiveRecord::Migration[5.2]
  def up
    remove_column :projects, :are_contributions_enabled
  end

  def down
    add_column :projects, :are_contributions_enabled, :boolean,
               null: false, default: false
  end
end
