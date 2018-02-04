# frozen_string_literal: true

require 'google/apis/drive_v3'

# Initialize Google Drive Service API if in development or production
if Rails.env.development? || Rails.env.production? ||
   (Rails.env.test? && ENV['MOCK_GOOGLE_DRIVE_REQUESTS'] != 'true')

  require 'googleauth'
  require 'googleauth/stores/file_token_store'

  Providers::GoogleDrive::Api.setup
  # TODO: Remove me once DB implementation is complete
  GoogleDrive.initialize
end
