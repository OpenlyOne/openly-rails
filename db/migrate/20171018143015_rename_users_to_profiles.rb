# frozen_string_literal: true

# Rename table 'users' to 'profiles' for Single-Table Inheritance
class RenameUsersToProfiles < ActiveRecord::Migration[5.1]
  def change
    rename_table 'users', 'profiles'
    add_column :profiles, :type, :string, null: false
  end
end
