# frozen_string_literal: true

# Merge separate class Handle into STI class Profile
class MergeHandleIntoProfiles < ActiveRecord::Migration[5.1]
  def change
    add_column :profiles, :handle, :citext, null: false
    add_index :profiles, :handle, unique: true

    drop_table :handles do |t|
      t.citext :identifier, null: false
      t.references :profile, polymorphic: true, index: false, null: false

      t.timestamps

      t.index :identifier, unique: true
      t.index %i[profile_type profile_id], unique: true
    end
  end
end
