# frozen_string_literal: true

module Providers
  module GoogleDrive
    # Wrapper class for Google Drive API
    class Api
      class << self
        # Create a Google Drive file
        def create_file(name, parent_id, mime_type)
          file = drive_file.new(name: name,
                                parents: [parent_id],
                                mime_type: mime_type)

          drive_service.create_file(file, fields: default_file_fields)
        end

        # Create a Google Drive file in home folder
        def create_file_in_home_folder(name, mime_type)
          file = drive_file.new(name: name, mime_type: mime_type)

          drive_service.create_file(file, fields: default_file_fields)
        end

        # Delete a file by ID
        def delete_file(id)
          drive_service.delete_file(id)
        end

        # Fetch a file by ID
        def fetch_file(id)
          drive_service.get_file(id, fields: default_file_fields)
        end

        # Setup the GoogleDrive API
        def setup
          initialize_drive_service
        end

        # Update the name of the file identified by ID
        def update_file_name(id, name)
          drive_service.update_file(id,
                                    drive_file.new(name: name),
                                    fields: default_file_fields)
        end

        # Update the parents of the file identified by ID
        def update_file_parents(id, add:, remove:)
          drive_service.update_file(
            id, nil,
            add_parents: add.compact, remove_parents: remove.compact,
            fields: default_file_fields
          )
        end

        private

        # ClientId holds the application's id and secret
        def auth_client_id
          Google::Auth::ClientId.new(ENV['GOOGLE_DRIVE_CLIENT_ID'],
                                     ENV['GOOGLE_DRIVE_CLIENT_SECRET'])
        end

        # UserAuthorizer based on the application's id and secret and token
        # store
        def authorizer
          Google::Auth::UserAuthorizer.new(auth_client_id,
                                           Google::Apis::DriveV3::AUTH_DRIVE,
                                           token_store)
        end

        # Class for Google Drive files
        def drive_file
          Google::Apis::DriveV3::File
        end

        # Return the instance of Google::Apis::DriveV3::DriveService
        def drive_service
          @drive_service || initialize_drive_service
        end

        # The default fields for file query methods
        def default_file_fields
          %w[id name mimeType parents].join(',')
        end

        # Initialize the Google::Apis::DriveV3::DriveService
        def initialize_drive_service
          @drive_service = Google::Apis::DriveV3::DriveService.new
          # TODO: Change name
          @drive_service.client_options.application_name =
            'Drive API Ruby Quickstart'
          @drive_service.authorization = authorizer.get_credentials(
            ENV['GOOGLE_DRIVE_TRACKING_ACCOUNT']
          )
          @drive_service
        end

        # FileTokenStore stores the access token in a file
        def token_store
          Google::Auth::Stores::FileTokenStore.new(
            file: File.join(ENV['GOOGLE_DRIVE_CREDENTIALS_PATH'])
          )
        end
      end
    end
  end
end
