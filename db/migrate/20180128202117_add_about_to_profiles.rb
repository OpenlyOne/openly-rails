# frozen_string_literal: true

# Add about text (description) to profiles
class AddAboutToProfiles < ActiveRecord::Migration[5.1]
  def change
    add_column :profiles, :about, :text
  end
end
