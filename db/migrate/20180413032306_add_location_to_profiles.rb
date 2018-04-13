# frozen_string_literal: true

# Add location column to profiles table
class AddLocationToProfiles < ActiveRecord::Migration[5.1]
  def change
    add_column :profiles, :location, :text, index: true
  end
end
