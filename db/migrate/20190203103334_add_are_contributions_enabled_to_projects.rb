class AddAreContributionsEnabledToProjects < ActiveRecord::Migration[5.2]
  def change
    add_column :projects, :are_contributions_enabled, :boolean,
               null: false, default: false
  end
end
