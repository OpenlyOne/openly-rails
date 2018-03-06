# frozen_string_literal: true

module Providers
  module GoogleDrive
    # Wrapper class for Google Drive API Drive Service
    class DriveService < Google::Apis::DriveV3::DriveService
      class << self
        # UserAuthorizer based on the application's id and secret and token
        # store
        def authorizer
          @authorizer ||=
            Google::Auth::UserAuthorizer.new(auth_client_id,
                                             Google::Apis::DriveV3::AUTH_DRIVE,
                                             token_store)
        end

        private

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

      attr_reader :google_account

      # Initialize a new instance of DriveService
      def initialize(google_account)
        super()
        client_options.application_name = 'Upshift One'
        @google_account = google_account
        reload
      end

      # Reload the DriveService (refresh credentials from disk)
      # Return self for chaining
      def reload
        self.authorization =
          self.class.authorizer.get_credentials(google_account)

        self
      end
    end
  end
end
