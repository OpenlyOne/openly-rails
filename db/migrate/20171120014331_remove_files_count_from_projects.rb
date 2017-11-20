# frozen_string_literal: true

# Projects do not need to keep track of how many files they have
class RemoveFilesCountFromProjects < ActiveRecord::Migration[5.1]
  def up
    remove_column :projects, :files_count
  end

  def down
    add_column :projects, :files_count, :integer, default: 0, null: false
    Project.find_each(&:reset_files_count!)
  end
end
