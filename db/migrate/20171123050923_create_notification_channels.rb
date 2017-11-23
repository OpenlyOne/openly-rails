# frozen_string_literal: true

# Create table for storing Delayed Job background jobs
class CreateNotificationChannels < ActiveRecord::Migration[5.1]
  def change
    create_table :notification_channels do |t|
      t.references :project, foreign_key: true, null: false
      t.references :file_item, foreign_key: true, null: false
      t.integer :status, index: true, default: 0, null: false
      t.datetime :expires_at

      t.timestamps
    end
  end
end
