class RemoveIsAcceptedFromContributions < ActiveRecord::Migration[5.2]
  def up
    remove_column :contributions, :is_accepted
  end

  def down
    add_column :contributions, :is_accepted, :boolean,
               default: false, null: false

    Contribution.reset_column_information
    Contribution.find_each do |contribution|
      contribution.update_column(
        :is_accepted, contribution.accepted_revision_id.present?
      )
    end
  end
end
