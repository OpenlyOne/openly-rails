# frozen_string_literal: true

RSpec.describe Providers::GoogleDrive::FileSync, type: :model, vcr: true do
  before  { prepare_google_drive_test }
  after   { tear_down_google_drive_test }

  describe '.create(name:, parent_id:, mime_type:, api_connection: nil)' do
    subject(:created_file)  { @created_file }
    let(:document_type)     { Providers::GoogleDrive::MimeType.document }

    before do
      # Create file and get id
      file_sync = described_class.create(
        name: 'Test File',
        parent_id: google_drive_test_folder_id,
        mime_type: document_type
      )

      # Fetch created file information
      @created_file = described_class.new(file_sync.id)
    end

    it "creates a file named 'Test File'" do
      expect(created_file.name).to eq 'Test File'
    end

    it 'places file in test folder' do
      expect(created_file.parent_id).to eq google_drive_test_folder_id
    end

    it 'sets mime type to document' do
      expect(created_file.mime_type).to eq document_type
    end

    it 'restricts access to creator' do
      expect(created_file.permissions.map(&:email_address))
        .to contain_exactly(Settings.google_drive_tracking_account)
    end
  end

  describe '.upload(name:, parent_id:, mime_type:, file:, ...)' do
    subject(:uploaded_file) do
      described_class.upload(
        name: 'Test File',
        parent_id: google_drive_test_folder_id,
        mime_type: document_type,
        file: word_doc
      )
    end

    let(:document_type) { Providers::GoogleDrive::MimeType.word_docx }
    let(:path_to_file_fixtures) do
      Rails.root.join('spec', 'support', 'fixtures', 'files')
    end
    let(:word_doc) { File.new(path_to_file_fixtures.join('file.docx')) }

    it 'creates a file with the correct metadata' do
      expect(uploaded_file.name).to eq 'Test File'
      expect(uploaded_file.parent_id).to eq google_drive_test_folder_id
      expect(uploaded_file.mime_type).to eq document_type
    end

    it 'uploads the document' do
      downloaded_file = Tempfile.new.tap(&:binmode)
      begin
        uploaded_file.download(destination: downloaded_file)
        expect(FileUtils).to be_identical(downloaded_file, word_doc)
      ensure
        downloaded_file.close!
      end
    end

    it 'restricts access to creator' do
      expect(uploaded_file.permissions.map(&:email_address))
        .to contain_exactly(Settings.google_drive_tracking_account)
    end
  end

  describe '#content' do
    subject(:file_with_content) do
      described_class.create(
        name: 'A File with Content',
        parent_id: google_drive_test_folder_id,
        mime_type: Providers::GoogleDrive::MimeType.document
      )
    end

    let(:content) { "Super super amazing content!\r\nHello world!" }

    before do
      # Write content to the file
      Providers::GoogleDrive::ApiConnection
        .default.update_file_content(file_with_content.id, content)
    end

    it 'retrieves the content' do
      expect(file_with_content.content).to eq(content)
    end
  end

  describe '#content_version' do
    subject(:content_version) do
      described_class.new(file_sync.id).content_version
    end
    let!(:file_sync) do
      described_class.create(
        name: 'Test File',
        parent_id: google_drive_test_folder_id,
        mime_type: mime_type
      )
    end
    let(:mime_type) { Providers::GoogleDrive::MimeType.document }

    it { is_expected.to eq '1' }

    context 'when file content is updated' do
      before do
        Providers::GoogleDrive::ApiConnection
          .default
          .update_file_content(file_sync.id, 'new file content')
      end

      it { is_expected.not_to eq '1' }
    end

    context 'when file is folder' do
      let(:mime_type) { Providers::GoogleDrive::MimeType.folder }
      it { is_expected.to eq '1' }
    end

    # TODO: Add spec for binary file type and ensure that version ID is not 0!
  end

  describe '.download(destination:)' do
    subject(:download) { file.download(destination: downloaded_file) }

    let(:downloaded_file) { Tempfile.new.tap(&:binmode) }
    let(:file) do
      described_class.create(
        name: 'Test File',
        parent_id: google_drive_test_folder_id,
        mime_type: mime_type
      )
    end
    let(:mime_type_class) { Providers::GoogleDrive::MimeType }

    before  { download }
    after   { downloaded_file.close! }

    context 'when file to download is word doc' do
      let(:file) do
        described_class.upload(
          name: 'Test File',
          parent_id: google_drive_test_folder_id,
          mime_type: Providers::GoogleDrive::MimeType.word_docx,
          file: word_doc
        )
      end
      let(:path_to_file_fixtures) do
        Rails.root.join('spec', 'support', 'fixtures', 'files')
      end
      let(:word_doc) { File.new(path_to_file_fixtures.join('file.docx')) }

      it 'downloads the document exactly as uploaded' do
        expect(FileUtils).to be_identical(downloaded_file, word_doc)
      end
    end

    context 'when file is a Google Doc' do
      let(:mime_type) { mime_type_class.document }

      it 'downloads as .docx' do
        downloaded_file.rewind
        expect(Henkei::Server.extract_content_type(downloaded_file))
          .to eq mime_type_class.new(mime_type).export_as
      end
    end

    context 'when file is a Google Sheet' do
      xit 'downloads as .xlxs'
    end
    context 'when file is a Google Slides presentation' do
      xit 'downloads as .pptx'
    end
    context 'when file is a Google Drawing' do
      xit 'downloads as .png'
    end
  end

  describe '#duplicate(name:, parent_id:)' do
    subject(:duplicated_file) { @duplicated_file }

    let(:original_file) do
      described_class.create(
        name: 'Test File',
        parent_id: google_drive_test_folder_id,
        mime_type: Providers::GoogleDrive::MimeType.document
      )
    end

    let(:subfolder) do
      described_class.create(
        name: 'Subfolder',
        parent_id: google_drive_test_folder_id,
        mime_type: Providers::GoogleDrive::MimeType.folder
      )
    end

    before do
      # Write content to the original file
      Providers::GoogleDrive::ApiConnection
        .default
        .update_file_content(original_file.id, "Amazing content!\r\nYes!")

      # Duplicate the file
      @duplicated_file =
        original_file.duplicate(name: 'Duplicate', parent_id: subfolder.id)
    end

    it 'duplicates the file' do
      expect(duplicated_file.content).to eq(original_file.content)
      expect(duplicated_file.name).to eq 'Duplicate'
      expect(duplicated_file.parent_id).to eq subfolder.id
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
      @renamed_file = described_class.new(file_sync.id)
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
      @relocated_file = described_class.new(file_sync.id)
    end

    it 'relocates file to subfolder' do
      expect(relocated_file.parent_id).to eq subfolder_id
    end
  end

  describe '#thumbnail' do
    subject(:thumbnail) do
      described_class.new(file_sync.id).thumbnail
    end
    let!(:file_sync) do
      described_class.create(
        name: 'Test File',
        parent_id: google_drive_test_folder_id,
        mime_type: mime_type
      )
    end
    let(:mime_type) { Providers::GoogleDrive::MimeType.document }
    # Sleep 5 seconds to ensure that Google has had time to generate the
    # thumbnail
    let(:wait)      { sleep 5 if VCR.current_cassette.recording? }

    context 'when file has no content' do
      let(:mime_type) { Providers::GoogleDrive::MimeType.folder }
      before          { wait }
      it              { is_expected.to eq nil }
    end

    context 'when file has content' do
      before do
        Providers::GoogleDrive::ApiConnection
          .default
          .update_file_content(file_sync.id, 'new file content')
        wait
      end

      it { expect(subject[0, 4]).to eq "\x89PNG".b }
    end

    context 'when file is folder' do
      let(:mime_type) { Providers::GoogleDrive::MimeType.folder }
      before          { wait }
      it              { is_expected.to eq nil }
    end
  end

  describe 'trashed file' do
    subject(:trashed_file) { @trashed_file }

    before do
      # Create file and get id
      file_sync = described_class.create(
        name: 'Test File',
        parent_id: google_drive_test_folder_id,
        mime_type: Providers::GoogleDrive::MimeType.document
      )

      # Trash file
      Providers::GoogleDrive::ApiConnection.default.trash_file(file_sync.id)

      # Fetch trashed file information
      @trashed_file = described_class.new(file_sync.id)
    end

    it 'is marked as deleted and returns nil values' do
      is_expected.to be_deleted
      expect(trashed_file.name).to eq nil
      expect(trashed_file.parent_id).to eq nil
      expect(trashed_file.thumbnail).to eq nil
    end
  end

  describe 'deleted file' do
    subject(:deleted_file) { @deleted_file }

    before do
      # Create file and get id
      file_sync = described_class.create(
        name: 'Test File',
        parent_id: google_drive_test_folder_id,
        mime_type: Providers::GoogleDrive::MimeType.document
      )

      # Delete file
      Providers::GoogleDrive::ApiConnection.default.delete_file(file_sync.id)

      # Fetch trashed file information
      @deleted_file = described_class.new(file_sync.id)
    end

    it 'is marked as deleted and returns nil values' do
      is_expected.to be_deleted
      expect(deleted_file.name).to eq nil
      expect(deleted_file.parent_id).to eq nil
      expect(deleted_file.thumbnail).to eq nil
    end
  end
end
