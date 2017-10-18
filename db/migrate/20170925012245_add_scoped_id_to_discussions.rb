# frozen_string_literal: true

# Add project-scoped ID to discussions
class AddScopedIdToDiscussions < ActiveRecord::Migration[5.1]
  def change
    add_column :discussions, :scoped_id, :integer, null: false
    add_index :discussions, :scoped_id
  end
end
