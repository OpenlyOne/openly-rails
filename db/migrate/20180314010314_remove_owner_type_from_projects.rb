# frozen_string_literal: true

# Remove owner_type column from projects table (because it no longer needs to be
# a polymorphic association)
class RemoveOwnerTypeFromProjects < ActiveRecord::Migration[5.1]
  def up
    remove_column :projects, :owner_type
    add_index :projects, :owner_id
    add_index :projects, %i[owner_id slug], unique: true
  end

  def down
    remove_reference :projects, :owner
    add_reference :projects, :owner, polymorphic: true, null: false
    add_index :projects, %i[owner_type owner_id slug], unique: true
  end
end
