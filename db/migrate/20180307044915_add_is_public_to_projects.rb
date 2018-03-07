# frozen_string_literal: true

# Add support for public and private projects
class AddIsPublicToProjects < ActiveRecord::Migration[5.1]
  def change
    add_column :projects, :is_public, :boolean, null: false, default: false
  end
end
