# frozen_string_literal: true

# Store information about Google Drive notification channels
class NotificationChannel < ApplicationRecord
  belongs_to :project
  belongs_to :file, class_name: 'FileItems::Base', foreign_key: 'file_item_id'

  enum status: %w[pending active]

  # Generate a unique channel_name based on the channel's ID
  # It is based on the Rails environment, the channel's ID, and the timestamp
  # (to ensure uniqueness)
  # For example: channel-test-572-20171111152233
  def unique_channel_name
    return nil unless id

    "channel-#{Rails.env}-#{id}-#{Time.zone.now.utc.strftime('%Y%M%d%H%M%S')}"
  end
end
