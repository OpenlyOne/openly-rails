# frozen_string_literal: true

# Create handle model (for usernames, teamnames, ...)
class CreateHandles < ActiveRecord::Migration[5.1]
  def change
    enable_extension 'citext'

    create_table :handles do |t|
      t.citext :identifier, null: false
      t.references :profile, polymorphic: true, index: false, null: false

      t.timestamps

      t.index :identifier, unique: true
      t.index %i[profile_type profile_id], unique: true
    end
  end
end
