# frozen_string_literal: true

# Create table for project files
class CreateFileItems < ActiveRecord::Migration[5.1]
  def change
    create_table :file_items do |t|
      t.references :project, foreign_key: true, null: false
      t.bigint :parent_id, null: true
      t.string :google_drive_id, null: false
      t.text :name, null: false
      t.string :mime_type, null: false

      t.timestamps

      t.foreign_key :file_items, column: :parent_id
      t.index :parent_id
      t.index :google_drive_id
    end
  end
end
