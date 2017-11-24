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
# rubocop:disable Metrics/ModuleLength
module GoogleDriveHelper
  # mocks google drive requests
  def mock_google_drive_requests
    allow(GoogleDrive).to receive(:get_file) do |file_id|
      GoogleDriveHelper.get_file(file_id)
    end

    allow(GoogleDrive).to receive(:list_files_in_folder) do |folder_id|
      GoogleDriveHelper.list_files_in_folder(folder_id)
    end

    allow(GoogleDrive).to receive(:list_changes) do |token, _page_size = nil|
      GoogleDriveHelper.list_changes(token)
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
            :with_kind,
            id: file[:id],
            type: file[:type],
            name: file[:name])
    end

    # List changes since token (imaginary data)
    # rubocop:disable Metrics/MethodLength
    def list_changes(token)
      case token.to_i
      when 999_999_999, 21
        Google::Apis::DriveV3::ChangeList.new(
          new_start_page_token: '100',
          changes: []
        )
      when 1
        folder_id = Settings.google_drive_test_folder_id
        files = GoogleDriveHelper.files.select { |f| f[:parent] == folder_id }

        changes =
          files.map do |file|
            build(
              :google_drive_change,
              id: file[:id],
              name: file[:name],
              parent: file[:parent],
              version: file[:version]
            )
          end

        Google::Apis::DriveV3::ChangeList.new(
          next_page_token: '21',
          changes: changes
        )
      end
    end
    # rubocop:enable Metrics/MethodLength

    # List files in folder
    def list_files_in_folder(folder_id)
      files = GoogleDriveHelper.files.select { |f| f[:parent] == folder_id }

      return [] unless files

      files.map do |file|
        build(:google_drive_file,
              id: file[:id],
              type: file[:type],
              name: file[:name],
              version: file[:version],
              modified_time: file[:modified_time].to_datetime)
      end
    end

    # rubocop:disable Metrics/MethodLength
    def files
      [
        # Root
        {
          id: '1_T9Pw8YGc0y5iWOSX-90SzQ1CTUGFmKR',
          name: 'Test for Upshift One',
          type: 'folder',
          version: 84,
          modified_time: 'Fri, 24 Nov 2017 06:20:34.555521217 +0000'.to_time
        },

        # Test for Upshift
        {
          id: '1tn7xT9i3EWHMLK7kAKHOXAM0MjYTWeMn',
          name: 'Interesting Documents',
          type: 'folder',
          parent: '1_T9Pw8YGc0y5iWOSX-90SzQ1CTUGFmKR',
          version: 4,
          modified_time: 'Mon, 20 Nov 2017 04:13:47.406000000 +0000'.to_time
        },
        {
          id: '1te4r398aV4rAYCtZaaTdKw_rMCQ4ExDHovQNVT54v2o',
          name: 'A Spreadsheet',
          type: 'spreadsheet',
          parent: '1_T9Pw8YGc0y5iWOSX-90SzQ1CTUGFmKR',
          version: 8,
          modified_time: 'Sun, 19 Nov 2017 22:53:33.800000000 +0000'.to_time
        },
        {
          id: '1uRT5v2xaAYaL41Fv9nYf3f85iadX2A-KAIEQIFPzKNY',
          name: 'A Google Doc',
          type: 'document',
          parent: '1_T9Pw8YGc0y5iWOSX-90SzQ1CTUGFmKR',
          version: 15,
          modified_time: 'Sun, 19 Nov 2017 22:51:37.241000000 +0000'.to_time
        },

        # Interesting documents
        {
          id: '151tFN9HxkCVwDQId9aFw3sPKZmt7eELi',
          name: 'Even More Interesting Documents',
          type: 'folder',
          parent: '1tn7xT9i3EWHMLK7kAKHOXAM0MjYTWeMn',
          version: 3,
          modified_time: 'Mon, 20 Nov 2017 04:32:55.707000000 +0000'.to_time
        },
        {
          id: '1zhT2xUVU7CCiLHTgIwLpyu6RXwL5ilRlyxDHQBSM0f4',
          name: 'Funny Cat Pictures',
          type: 'presentation',
          parent: '1tn7xT9i3EWHMLK7kAKHOXAM0MjYTWeMn',
          version: 6,
          modified_time: 'Mon, 20 Nov 2017 04:15:27.329000000 +0000'.to_time
        },

        # Even more interesting documents
        {
          id: '1eZB7MloaAVIc1NNT0fr1buESBwB7IX1mXucRSHWibK4',
          name: 'A Pretty Drawing',
          type: 'drawing',
          parent: '151tFN9HxkCVwDQId9aFw3sPKZmt7eELi',
          version: 6,
          modified_time: 'Mon, 20 Nov 2017 04:35:02.158000000 +0000'.to_time
        }
      ]
    end
  end
end
