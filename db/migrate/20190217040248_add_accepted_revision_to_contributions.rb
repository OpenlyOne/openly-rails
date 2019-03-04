class AddAcceptedRevisionToContributions < ActiveRecord::Migration[5.2]
  def up
    add_reference :contributions, :accepted_revision,
                  foreign_key: { to_table: :vcs_commits }

    Contribution.reset_column_information
    Contribution.includes(:project).find_each do |contribution|
      accepted_revision =
        contribution.project.revisions.find_by(
          title: contribution.title,
          summary: contribution.description,
          author_id: contribution.creator_id
        )
      contribution.update_column(:accepted_revision_id,
                                 accepted_revision&.id)
    end
  end

  def down
    remove_reference :contributions, :accepted_revision
  end
end
