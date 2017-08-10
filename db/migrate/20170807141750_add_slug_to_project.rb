# frozen_string_literal: true

# Add unique identifier slug to project
class AddSlugToProject < ActiveRecord::Migration[5.1]
  def change
    add_column :projects, :slug, :citext, null: false
    add_index :projects, %i[owner_type owner_id slug], unique: true
  end
end
