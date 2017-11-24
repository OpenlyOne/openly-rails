# frozen_string_literal: true

RSpec.describe GoogleDriveHelper, live_google_drive_requests: true do
  describe 'get_file' do
    context 'file_root_folder' do
      let!(:orig)     { GoogleDrive.get_file(file_id) }
      before          { mock_google_drive_requests }
      let!(:mock)     { GoogleDrive.get_file(file_id) }
      let(:file_id)   { Settings.google_drive_test_folder_id }
      it              { expect(orig.to_h).to eq(mock.to_h) }
    end

    context 'doc: A Google Doc' do
      let!(:orig)     { GoogleDrive.get_file(file_id) }
      before          { mock_google_drive_requests }
      let!(:mock)     { GoogleDrive.get_file(file_id) }
      let(:file_id)   { '1uRT5v2xaAYaL41Fv9nYf3f85iadX2A-KAIEQIFPzKNY' }
      it              { expect(orig.to_h).to eq(mock.to_h) }
    end
  end

  describe 'list_changes(token, page_size)' do
    context 'token is 1, page_size is 5' do
      let!(:orig)     { GoogleDrive.list_changes(token, page_size) }
      before          { mock_google_drive_requests }
      let!(:mock)     { GoogleDrive.list_changes(token, page_size) }
      let(:token)     { 1 }
      let(:page_size) { 5 }
      it do
        expect(orig.to_h.except(:changes))
          .to eq(mock.to_h.except(:changes))
      end
    end

    context 'token is 999_999_999, page_size is default' do
      let!(:orig) { GoogleDrive.list_changes(token) }
      before      { mock_google_drive_requests }
      let!(:mock) { GoogleDrive.list_changes(token) }
      let(:token) { 999_999_999 }
      it do
        expect(orig.to_h.except(:new_start_page_token))
          .to eq(mock.to_h.except(:new_start_page_token))
      end
    end
  end

  describe 'list_files_in_folder' do
    context 'root folder' do
      let!(:orig)     { GoogleDrive.list_files_in_folder(folder_id) }
      before          { mock_google_drive_requests }
      let!(:mock)     { GoogleDrive.list_files_in_folder(folder_id) }
      let(:folder_id) { Settings.google_drive_test_folder_id }
      it { expect(orig.map(&:to_h)).to eq(mock.map(&:to_h)) }
    end

    context 'folder: Interesting Documents' do
      let!(:orig)     { GoogleDrive.list_files_in_folder(folder_id) }
      before          { mock_google_drive_requests }
      let!(:mock)     { GoogleDrive.list_files_in_folder(folder_id) }
      let(:folder_id) { '1tn7xT9i3EWHMLK7kAKHOXAM0MjYTWeMn' }
      it { expect(orig.map(&:to_h)).to eq(mock.map(&:to_h)) }
    end

    context 'folder: Even More Interesting Documents' do
      let!(:orig)     { GoogleDrive.list_files_in_folder(folder_id) }
      before          { mock_google_drive_requests }
      let!(:mock)     { GoogleDrive.list_files_in_folder(folder_id) }
      let(:folder_id) { '151tFN9HxkCVwDQId9aFw3sPKZmt7eELi' }
      it { expect(orig.map(&:to_h)).to eq(mock.map(&:to_h)) }
    end
  end
end
