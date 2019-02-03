class AddIsAcceptedToContributions < ActiveRecord::Migration[5.2]
  def change
    add_column :contributions, :is_accepted, :boolean,
               default: false, null: false
  end
end
