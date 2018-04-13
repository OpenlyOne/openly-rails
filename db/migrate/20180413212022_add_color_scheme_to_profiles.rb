# frozen_string_literal: true

# Add color scheme column to profiles
class AddColorSchemeToProfiles < ActiveRecord::Migration[5.1]
  def change
    add_column :profiles, :color_scheme, :string, null: false,
                                                  default: 'blue darken-2'
  end
end
