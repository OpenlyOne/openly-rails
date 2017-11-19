# frozen_string_literal: true

require 'google/apis/drive_v3'

# Initialize Google Drive Service API if in development or production
if Rails.env.development? || Rails.env.production?
  require 'googleauth'
  require 'googleauth/stores/file_token_store'

  GoogleDrive.initialize
end
