# frozen_string_literal: true

# Wrapper class for Google Drive API
class GoogleDrive
  class << self
    # Delegations
    delegate :get_file, to: :@drive_service

    # Initialize the Google::Apis::DriveV3::DriveService
    def initialize
      @drive_service = Google::Apis::DriveV3::DriveService.new
      @drive_service.client_options.application_name =
        'Drive API Ruby Quickstart'
      @drive_service.authorization = authorizer.get_credentials('default')
    end

    # Get children (files) of folder with ID id_of_folder
    def list_files_in_folder(id_of_folder)
      @drive_service.list_files(q: "'#{id_of_folder}' in parents").files
    end

    private

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
        file: File.join(Dir.home, ENV['GOOGLE_DRIVE_CREDENTIALS_PATH'])
      )
    end
  end
end
