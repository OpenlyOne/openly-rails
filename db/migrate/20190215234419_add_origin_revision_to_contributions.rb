class AddOriginRevisionToContributions < ActiveRecord::Migration[5.2]
  def up
    add_reference :contributions, :origin_revision,
                  foreign_key: { to_table: :vcs_commits }

    Contribution.reset_column_information
    Contribution.includes(:project).find_each do |contribution|
      contribution.update_column(:origin_revision_id,
                                 contribution.project.revisions.last&.id)
    end

    change_column_null :contributions, :origin_revision_id, false
  end

  def down
    remove_reference :contributions, :origin_revision
  end
end
