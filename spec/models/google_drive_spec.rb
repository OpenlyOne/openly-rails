# frozen_string_literal: true

RSpec.describe GoogleDrive, type: :model do
  before do
    mock_google_drive_requests if ENV['MOCK_GOOGLE_DRIVE_REQUESTS'] == 'true'
  end

  describe '.get_file' do
    subject(:method)  { GoogleDrive.get_file(id_of_file) }
    let(:id_of_file)  { Settings.google_drive_test_folder }

    it 'returns a file' do
      is_expected.to be_a Google::Apis::DriveV3::File
      expect(method.to_h).to have_key :id
      expect(method.to_h).to have_key :name
      expect(method.to_h).to have_key :mime_type
    end
  end

  describe '.list_files_in_folder(id_of_folder)' do
    subject(:method)    { GoogleDrive.list_files_in_folder(id_of_folder) }
    let(:id_of_folder)  { Settings.google_drive_test_folder }

    it 'returns an array of files' do
      subject.each do |file|
        expect(file).to be_a Google::Apis::DriveV3::File
      end
    end

    it 'contains 3 files' do
      expect(subject.count).to eq 3
    end

    it 'contains a Google folder' do
      file = subject.find do |f|
        f.id == '1tn7xT9i3EWHMLK7kAKHOXAM0MjYTWeMn'
      end

      expect(file.name).to eq 'Interesting Documents'
      expect(file.mime_type).to eq 'application/vnd.google-apps.folder'
    end

    it 'contains a Google Doc' do
      file = subject.find do |f|
        f.id == '1uRT5v2xaAYaL41Fv9nYf3f85iadX2A-KAIEQIFPzKNY'
      end

      expect(file.name).to eq 'A Google Doc'
      expect(file.mime_type).to eq 'application/vnd.google-apps.document'
    end

    it 'contains a Google Sheet' do
      file = subject.find do |f|
        f.id == '1te4r398aV4rAYCtZaaTdKw_rMCQ4ExDHovQNVT54v2o'
      end

      expect(file.name).to eq 'A Spreadsheet'
      expect(file.mime_type).to eq 'application/vnd.google-apps.spreadsheet'
    end
  end
end
