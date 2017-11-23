# frozen_string_literal: true

# Create a notification channel for listening to file updates and changes
class NotificationChannelJob < ApplicationJob
  queue_as :notification_channel
  queue_with_priority 60

  def perform(*args)
    variables_from_arguments(*args)

    # Create a new NotificationChannel
    channel = create_notification_channel

    # Watch the file in Google Drive
    response =
      GoogleDrive.watch_file(channel.unique_channel_name, @google_drive_id)

    # Update the NotificationChannel
    channel.update(expires_at: Time.strptime(response.expiration.to_s, '%Q'))
  end

  private

  # Create a new notification channel
  def create_notification_channel
    NotificationChannel.create(
      project_id: @reference_id,
      file_item_id: @file_id,
      status: :pending
    )
  end

  # Sets instance variables from the job's arguments
  def variables_from_arguments(*args)
    @reference_type   = args[0][:reference_type]
    @reference_id     = args[0][:reference_id]
    @file_id          = args[0][:file_id]
    @google_drive_id  = args[0][:google_drive_id]
  end
end
