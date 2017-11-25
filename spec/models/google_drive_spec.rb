# frozen_string_literal: true

RSpec.describe GoogleDrive, type: :model do
  before do
    mock_google_drive_requests if ENV['MOCK_GOOGLE_DRIVE_REQUESTS'] == 'true'
  end

  describe '.get_file' do
    subject(:method)  { GoogleDrive.get_file(id_of_file) }
    let(:id_of_file)  { Settings.google_drive_test_folder_id }

    it 'returns a file' do
      is_expected.to be_a Google::Apis::DriveV3::File
      expect(method.to_h).to have_key :id
      expect(method.to_h).to have_key :name
      expect(method.to_h).to have_key :mime_type
      expect(method.to_h).to have_key :version
      expect(method.to_h).to have_key :modified_time
    end
  end

  describe '.link_to_id(link_to_file)' do
    subject(:method) { GoogleDrive.link_to_id(link) }
    context 'link 1' do
      let(:link) do
        'https://drive.google.com/drive/u/0/folders/' \
        '12_INPj21eSprpRq7A9OUF0r1jHdpiA4R'
      end
      it { is_expected.to eq '12_INPj21eSprpRq7A9OUF0r1jHdpiA4R' }
    end
    context 'link 2' do
      let(:link) do
        'https://drive.google.com/drive/u/2/folders/' \
        '0B2ioM1QJEE9kTDNrdUFfVG5XZDg'
      end
      it { is_expected.to eq '0B2ioM1QJEE9kTDNrdUFfVG5XZDg' }
    end
    context 'link 3' do
      let(:link) do
        'https://drive.google.com/drive/folders/' \
        '1_T9Pw8YGc0y5iWOSX-90SzQ1CTUGFmKR'
      end
      it { is_expected.to eq '1_T9Pw8YGc0y5iWOSX-90SzQ1CTUGFmKR' }
    end
    context 'not a link' do
      let(:link) do
        'https://drive.google.com/drive/fol/'
      end
      it { is_expected.to eq nil }
    end
  end

  describe '.list_changes(token, page_size)' do
    subject(:method) { GoogleDrive.list_changes(token, page_size) }
    before do
      allow(GoogleDrive).to receive(:list_changes).and_call_original
      allow(GoogleDrive).to receive(:drive_service).and_return(service)
    end
    let(:service)     { Google::Apis::DriveV3::DriveService.new }
    let(:token)       { 55 }
    let(:page_size)   { 20 }

    it 'calls list_changes with token=55 and page_size=20' do
      expect_any_instance_of(Google::Apis::DriveV3::DriveService)
        .to receive(:list_changes).with(55, hash_including(page_size: 20))
      subject
    end

    context 'query fields' do
      let(:fields) { @fields.split(', ') }
      before do
        @fields = nil
        allow_any_instance_of(Google::Apis::DriveV3::DriveService)
          .to receive(:list_changes) do |_instance, _token, options|
            @fields = options[:fields]
          end
        subject
      end

      it 'queries nextPageToken, newStartPageToken' do
        expect(fields).to include 'nextPageToken'
        expect(fields).to include 'newStartPageToken'
      end

      it 'queries the type of change' do
        expect(fields).to include 'changes/type'
      end

      it 'queries for file id' do
        expect(fields).to include 'changes/file_id'
      end

      it 'queries for file mime type' do
        expect(fields).to include 'changes/file/mimeType'
      end

      it 'queries for file version' do
        expect(fields).to include 'changes/file/version'
      end

      it 'queries for file name' do
        expect(fields).to include 'changes/file/name'
      end

      it 'queries for file modified time' do
        expect(fields).to include 'changes/file/modifiedTime'
      end

      it 'queries for file parents' do
        expect(fields).to include 'changes/file/parents'
      end

      it 'queries for removal' do
        expect(fields).to include 'changes/removed'
        expect(fields).to include 'changes/file/trashed'
      end
    end

    context 'when page_size is not passed' do
      subject(:method) { GoogleDrive.list_changes(token) }

      it 'calls list_changes with token and page_size=100' do
        expect_any_instance_of(Google::Apis::DriveV3::DriveService)
          .to receive(:list_changes).with(55, hash_including(page_size: 100))
        subject
      end
    end
  end

  describe '.list_files_in_folder(id_of_folder)' do
    subject(:method)    { GoogleDrive.list_files_in_folder(id_of_folder) }
    let(:id_of_folder)  { Settings.google_drive_test_folder_id }

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

    context 'query fields' do
      before do
        allow(GoogleDrive).to receive(:list_files_in_folder).and_call_original
        allow(GoogleDrive).to receive(:drive_service).and_return(service)
      end
      let(:service) { Google::Apis::DriveV3::DriveService.new }
      let(:fields)  { @fields.split(', ') }
      before do
        @fields = nil
        allow_any_instance_of(Google::Apis::DriveV3::DriveService)
          .to receive(:list_files) do |_instance, options|
            @fields = options[:fields]
          end.and_return(Google::Apis::DriveV3::FileList.new(files: []))
        subject
      end

      it 'queries for file id' do
        expect(fields).to include 'files/id'
      end

      it 'queries for file version' do
        expect(fields).to include 'files/version'
      end

      it 'queries the file mime type' do
        expect(fields).to include 'files/mimeType'
      end

      it 'queries for file name' do
        expect(fields).to include 'files/name'
      end

      it 'queries for file modified time' do
        expect(fields).to include 'files/modifiedTime'
      end
    end
  end
end
