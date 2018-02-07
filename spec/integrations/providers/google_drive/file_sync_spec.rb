# frozen_string_literal: true

RSpec.describe Providers::GoogleDrive::FileSync, type: :model, vcr: true do
  before  { prepare_google_drive_test }
  after   { tear_down_google_drive_test }

  describe '.create(name:, parent_id:, mime_type:, api_connection: nil)' do
    subject(:created_file) { @created_file }

    before do
      # Create file and get id
      file_sync = described_class.create(
        name: 'Test File',
        parent_id: google_drive_test_folder_id,
        mime_type: Providers::GoogleDrive::MimeType.document
      )

      # Fetch created file information
      @created_file = described_class.new(id: file_sync.id)
    end

    it "creates a file named 'Test File'" do
      expect(created_file.name).to eq 'Test File'
    end

    it 'places file in test folder' do
      expect(created_file.parent_id).to eq google_drive_test_folder_id
    end
  end

  describe '#rename(name)' do
    subject(:renamed_file) { @renamed_file }

    before do
      # Create file and get id
      file_sync = described_class.create(
        name: 'Test File',
        parent_id: google_drive_test_folder_id,
        mime_type: Providers::GoogleDrive::MimeType.document
      )

      # Rename file to: Renamed Test File
      file_sync.rename('Renamed Test File')

      # Fetch renamed file information
      @renamed_file = described_class.new(id: file_sync.id)
    end

    it "renames file to 'Renamed Test File'" do
      expect(renamed_file.name).to eq 'Renamed Test File'
    end
  end

  describe '#relocate(to:, from:)' do
    subject(:relocated_file)  { @relocated_file }
    let(:subfolder_id)        { @subfolder.id }

    before do
      # Create file and get id
      file_sync = described_class.create(
        name: 'Test File',
        parent_id: google_drive_test_folder_id,
        mime_type: Providers::GoogleDrive::MimeType.document
      )

      # Create subfolder
      @subfolder = described_class.create(
        name: 'Subfolder',
        parent_id: google_drive_test_folder_id,
        mime_type: Providers::GoogleDrive::MimeType.folder
      )

      # Relocate file to subfolder
      file_sync.relocate(to: @subfolder.id, from: file_sync.parent_id)

      # Fetch relocated file information
      @relocated_file = described_class.new(id: file_sync.id)
    end

    it 'relocates file to subfolder' do
      expect(relocated_file.parent_id).to eq subfolder_id
    end
  end
end
