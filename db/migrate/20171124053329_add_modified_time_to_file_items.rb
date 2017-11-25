# frozen_string_literal: true

# Add modified time column to store Google Drive's modified_time for each file
class AddModifiedTimeToFileItems < ActiveRecord::Migration[5.1]
  def change
    add_column :file_items, :modified_time, :datetime, null: true
    add_column :file_items, :modified_time_at_last_commit, :datetime, null: true
  end
end
