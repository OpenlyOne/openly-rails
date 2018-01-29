# frozen_string_literal: true

# Add tags (case insensitive) to projects
class AddTagsToProjects < ActiveRecord::Migration[5.1]
  def change
    add_column :projects, :tags, :citext, array: true, default: []
  end
end
