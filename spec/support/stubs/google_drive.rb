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
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize

  # mocks google drive requests
  def mock_google_drive_requests
    # get_file: default
    allow(GoogleDrive).to receive(:get_file)
      .with(instance_of(String))
      .and_raise(
        Google::Apis::ClientError.exception('notFound: File not found')
      )

    # get_file: root_folder
    allow(GoogleDrive).to receive(:get_file)
      .with('1_T9Pw8YGc0y5iWOSX-90SzQ1CTUGFmKR')
      .and_return(GoogleDriveHelper.send(:file_root_folder))

    # root folder
    allow(GoogleDrive).to receive(:list_files_in_folder)
      .with('1_T9Pw8YGc0y5iWOSX-90SzQ1CTUGFmKR')
      .and_return(GoogleDriveHelper.send(:root_folder))

    # folder: interesting documents
    allow(GoogleDrive).to receive(:list_files_in_folder)
      .with('1tn7xT9i3EWHMLK7kAKHOXAM0MjYTWeMn')
      .and_return(GoogleDriveHelper.send(:f_interesting_documents))

    # folder: even more interesting documents
    allow(GoogleDrive).to receive(:list_files_in_folder)
      .with('151tFN9HxkCVwDQId9aFw3sPKZmt7eELi')
      .and_return(GoogleDriveHelper.send(:f_even_more_interesting_documents))
  end

  class << self
    private

    def file_root_folder
      build(:google_drive_file,
            id: '1_T9Pw8YGc0y5iWOSX-90SzQ1CTUGFmKR',
            type: 'folder',
            name: 'Test for Upshift One')
    end

    def root_folder
      [
        build(:google_drive_file,
              id: '1tn7xT9i3EWHMLK7kAKHOXAM0MjYTWeMn',
              type: 'folder',
              name: 'Interesting Documents'),
        build(:google_drive_file,
              id: '1te4r398aV4rAYCtZaaTdKw_rMCQ4ExDHovQNVT54v2o',
              type: 'spreadsheet',
              name: 'A Spreadsheet'),
        build(:google_drive_file,
              id: '1uRT5v2xaAYaL41Fv9nYf3f85iadX2A-KAIEQIFPzKNY',
              type: 'document',
              name: 'A Google Doc')
      ]
    end

    def f_interesting_documents
      [
        build(:google_drive_file,
              id: '151tFN9HxkCVwDQId9aFw3sPKZmt7eELi',
              type: 'folder',
              name: 'Even More Interesting Documents'),
        build(:google_drive_file,
              id: '1zhT2xUVU7CCiLHTgIwLpyu6RXwL5ilRlyxDHQBSM0f4',
              type: 'presentation',
              name: 'Funny Cat Pictures')
      ]
    end

    def f_even_more_interesting_documents
      [
        build(:google_drive_file,
              id: '1eZB7MloaAVIc1NNT0fr1buESBwB7IX1mXucRSHWibK4',
              type: 'drawing',
              name: 'A Pretty Drawing')
      ]
    end
  end
end
