# frozen_string_literal: true

# Create notifications table for managing notifications
class CreateActivityNotificationTables < ActiveRecord::Migration[5.1]
  def change
    create_table :notifications do |t|
      # Recipient of notification
      t.belongs_to :target,     polymorphic: true, index: true, null: false

      # Object of notification (message, comment, revision, ...)
      t.belongs_to :notifiable, polymorphic: true, index: true, null: false

      # Source of notification (user)
      t.belongs_to :notifier,   polymorphic: true, index: true

      # Grouping of notifications
      t.belongs_to :group, polymorphic: true, index: true
      t.integer    :group_owner_id,           index: true

      # Key identifier for the notification, such as project.revision
      t.string     :key, null: false

      # Additional parameters
      t.text       :parameters

      # Track when a notification is opened (read)
      t.datetime   :opened_at

      t.timestamps
    end
  end
end
