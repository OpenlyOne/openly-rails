class AddOriginRevisionToContributions < ActiveRecord::Migration[5.2]
  def change
    add_reference :contributions, :origin_revision,
                  foreign_key: { to_table: :vcs_commits }

    Contribution.reset_column_information
    Contribution.includes(:project).find_each do |contribution|
      contribution.update(origin_revision: contribution.project.revisions.last)
    end

    change_column_null :contributions, :origin_revision_id, false
  end
end
