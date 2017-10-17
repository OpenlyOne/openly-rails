# frozen_string_literal: true

# Projects keep a counter cache of files
class AddFileCountToProject < ActiveRecord::Migration[5.1]
  def change
    add_column :projects, :files_count, :integer, default: 0, null: false

    Project.find_each(&:reset_files_count!)
  end
end
