# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:each) do
    if ENV['MOCK_GOOGLE_DRIVE_REQUESTS'] == 'true'
      allow(GoogleDrive).to receive(:drive_service).and_return(nil)
    end
  end
end

include FactoryGirl::Syntax::Methods

# Mock Google Drive methods
module GoogleDriveHelper
  # rubocop:disable Metrics/MethodLength

  # mocks google drive requests
  def mock_google_drive_requests
    allow(GoogleDrive).to receive(:get_file) do |file_id|
      GoogleDriveHelper.get_file(file_id)
    end

    allow(GoogleDrive).to receive(:list_files_in_folder) do |folder_id|
      GoogleDriveHelper.list_files_in_folder(folder_id)
    end

    allow(GoogleDrive).to receive(:watch_file) do |channel_name, file_id|
      GoogleDriveHelper.watch_file(channel_name, file_id)
    end
  end

  class << self
    # Get a file by ID
    def get_file(file_id)
      file = GoogleDriveHelper.files.find { |f| f[:id] == file_id }

      unless file
        raise Google::Apis::ClientError.exception('notFound: File not found')
      end

      build(:google_drive_file,
            id: file[:id],
            type: file[:type],
            name: file[:name])
    end

    # List files in folder
    def list_files_in_folder(folder_id)
      files = GoogleDriveHelper.files.select { |f| f[:parent] == folder_id }

      return [] unless files

      files.map do |file|
        build(:google_drive_file,
              id: file[:id],
              type: file[:type],
              name: file[:name])
      end
    end

    # Create a notification channel for the file with the provided name
    def watch_file(channel_name, file_id)
      file = GoogleDriveHelper.files.find { |f| f[:id] == file_id }

      unless file
        return build(:google_drive_channel, id: channel_name, file_id: file_id)
      end

      build(:google_drive_channel,
            id: channel_name,
            resource_id: file[:resource_id],
            file_id: file_id)
    end

    def files
      [
        # Root
        {
          id: '1_T9Pw8YGc0y5iWOSX-90SzQ1CTUGFmKR',
          name: 'Test for Upshift One',
          type: 'folder',
          resource_id: 'YoTSmEXOGaaqvTjB6KJJ4aS2-XM'
        },

        # Test for Upshift
        {
          id: '1tn7xT9i3EWHMLK7kAKHOXAM0MjYTWeMn',
          name: 'Interesting Documents',
          type: 'folder',
          parent: '1_T9Pw8YGc0y5iWOSX-90SzQ1CTUGFmKR'
        },
        {
          id: '1te4r398aV4rAYCtZaaTdKw_rMCQ4ExDHovQNVT54v2o',
          name: 'A Spreadsheet',
          type: 'spreadsheet',
          parent: '1_T9Pw8YGc0y5iWOSX-90SzQ1CTUGFmKR'
        },
        {
          id: '1uRT5v2xaAYaL41Fv9nYf3f85iadX2A-KAIEQIFPzKNY',
          name: 'A Google Doc',
          type: 'document',
          parent: '1_T9Pw8YGc0y5iWOSX-90SzQ1CTUGFmKR'
        },

        # Interesting documents
        {
          id: '151tFN9HxkCVwDQId9aFw3sPKZmt7eELi',
          name: 'Even More Interesting Documents',
          type: 'folder',
          parent: '1tn7xT9i3EWHMLK7kAKHOXAM0MjYTWeMn'
        },
        {
          id: '1zhT2xUVU7CCiLHTgIwLpyu6RXwL5ilRlyxDHQBSM0f4',
          name: 'Funny Cat Pictures',
          type: 'presentation',
          parent: '1tn7xT9i3EWHMLK7kAKHOXAM0MjYTWeMn'
        },

        # Even more interesting documents
        {
          id: '1eZB7MloaAVIc1NNT0fr1buESBwB7IX1mXucRSHWibK4',
          name: 'A Pretty Drawing',
          type: 'drawing',
          parent: '151tFN9HxkCVwDQId9aFw3sPKZmt7eELi'
        }
      ]
    end
  end
end
