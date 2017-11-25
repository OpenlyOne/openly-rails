# frozen_string_literal: true

# Add parent ID at last commit to file items to track whether a file was moved
class AddParentIdAtLastCommitToFileItems < ActiveRecord::Migration[5.1]
  def change
    add_column :file_items, :parent_id_at_last_commit, :bigint, null: true
  end
end
