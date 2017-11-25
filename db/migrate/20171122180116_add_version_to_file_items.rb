# frozen_string_literal: true

# Add version info to files
class AddVersionToFileItems < ActiveRecord::Migration[5.1]
  def change
    add_column :file_items, :version, :bigint, null: false, default: 0
    add_column :file_items,
               :version_at_last_commit, :bigint, null: false, default: 0
  end
end
