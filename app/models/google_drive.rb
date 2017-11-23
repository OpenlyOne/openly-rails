# frozen_string_literal: true

# Wrapper class for Google Drive API
# This class is NOT covered by SimpleCov because we're mocking most of it in our
# CI testing.
class GoogleDrive
  class << self
    # Delegations
    delegate :get_file, to: :drive_service

    # Initialize the Google::Apis::DriveV3::DriveService
    def initialize
      @drive_service = Google::Apis::DriveV3::DriveService.new
      @drive_service.client_options.application_name =
        'Drive API Ruby Quickstart'
      @drive_service.authorization = authorizer.get_credentials('default')
    end

    # Retrieve the ID from a given link
    # Note: Tested for folders only
    def link_to_id(link_to_file)
      matches = link_to_file.match(%r{\/folders\/?(.+)})
      matches ? matches[1] : nil
    end

    # Get children (files) of folder with ID id_of_folder
    def list_files_in_folder(id_of_folder)
      drive_service.list_files(q: "'#{id_of_folder}' in parents").files
    end

    # Create a notification channel for a file with the provided name
    # Note: The notification channel name MUST be unique
    def watch_file(channel_name, id_of_file)
      expires_at =
        (Time.zone.now + Settings.google_drive_channel_duration)
        .to_datetime.strftime('%Q').to_i
      channel = Google::Apis::DriveV3::Channel.new(
        address: Settings.google_drive_webhook_url,
        id: channel_name,
        expiration: expires_at,
        type: 'web_hook'
      )
      drive_service.watch_file(id_of_file, channel)
    end

    private

    # Return the instance of Google::Apis::DriveV3:;DriveService
    # Initialize unless already initialized
    def drive_service
      initialize unless @drive_service
      @drive_service
    end

    # UserAuthorizer based on the application's id and secret and token store
    def authorizer
      Google::Auth::UserAuthorizer.new(auth_client_id,
                                       Google::Apis::DriveV3::AUTH_DRIVE,
                                       token_store)
    end

    # ClientId holds the application's id and secret
    def auth_client_id
      Google::Auth::ClientId.new(ENV['GOOGLE_DRIVE_CLIENT_ID'],
                                 ENV['GOOGLE_DRIVE_CLIENT_SECRET'])
    end

    # FileTokenStore stores the access token in a file
    def token_store
      Google::Auth::Stores::FileTokenStore.new(
        file: File.join(ENV['GOOGLE_DRIVE_CREDENTIALS_PATH'])
      )
    end
  end
end
