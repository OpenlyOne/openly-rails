# frozen_string_literal: true

require 'integrations/shared_examples/vcs/including_downloadable_integration.rb'
require 'integrations/shared_examples/vcs/including_snapshotable_integration.rb'
require 'integrations/shared_examples/vcs/including_syncable_integration.rb'

RSpec.describe VCS::StagedFile, type: :model do
  subject(:file) do
    described_class.new(
      remote_file_id: remote_file_id,
      branch: branch,
      file_record: file_record
    )
  end
  let(:branch)          { create :vcs_branch }
  let(:file_record)     { create :vcs_file_record }
  let(:remote_file_id)  { 'id' }

  it_should_behave_like 'vcs: including snapshotable integration' do
    let(:file)                    { build :vcs_staged_file }
    let(:snapshotable)            { file }
    let(:snapshotable_model_name) { 'VCS::StagedFile' }
  end

  it_should_behave_like 'vcs: including syncable integration' do
    let(:api)      { Providers::GoogleDrive::ApiConnection.default }
    let(:syncable) { file }
    let(:parent_id) { google_drive_test_folder_id }
    let(:mime_type) { Providers::GoogleDrive::MimeType.document }
    let(:folder_mime_type)  { Providers::GoogleDrive::MimeType.folder }
    let(:file_sync_class)   { Providers::GoogleDrive::FileSync }

    before { prepare_google_drive_test }
    after  { tear_down_google_drive_test }

    let!(:root) do
      create(:vcs_staged_file, :root, :folder,
             branch: branch, remote_file_id: parent_id)
    end
  end

  it_should_behave_like 'vcs: including downloadable integration' do
    let(:downloadable)    { file }
    let(:parent_id)       { google_drive_test_folder_id }
    let(:mime_type)       { Providers::GoogleDrive::MimeType.document }
    let(:file_sync_class) { Providers::GoogleDrive::FileSync }
    let(:user_acct)       { ENV['GOOGLE_DRIVE_USER_ACCOUNT'] }
    let(:account)         { create :account, email: user_acct }
    let(:project)         { create :project, owner: account.user }
    let(:branch)          { project.master_branch }

    before { prepare_google_drive_test }
    after  { tear_down_google_drive_test }

    let!(:root) do
      create(:vcs_staged_file, :root, :folder,
             branch: branch, remote_file_id: parent_id)
    end
  end

  describe 'snapshotable + syncable', :vcr do
    before { prepare_google_drive_test }
    after  { tear_down_google_drive_test }
    let!(:file_sync) do
      Providers::GoogleDrive::FileSync.create(
        name: 'Test File',
        parent_id: google_drive_test_folder_id,
        mime_type: Providers::GoogleDrive::MimeType.document
      )
    end
    let!(:parent) do
      described_class.new(
        remote_file_id: google_drive_test_folder_id,
        branch: branch,
        file_record: file_record_parent,
        is_root: true
      )
    end
    let(:file_record_parent)  { create :vcs_file_record }
    let(:projects)            { create_list :project, 3 }
    let(:api)                 { Providers::GoogleDrive::ApiConnection.default }
    let(:remote_file_id)      { file_sync.id }
    let(:file_from_database) do
      described_class.find_by_remote_file_id!(remote_file_id)
    end
    let(:file_attributes)     { file_from_database.attributes }
    let(:snapshot_attributes) { file_from_database.current_snapshot.attributes }
    let(:expected_attributes) do
      {
        'name' => 'Test File',
        'file_record_parent_id' => parent.file_record_id,
        'content_version' => '1',
        'mime_type' => Providers::GoogleDrive::MimeType.document,
        'remote_file_id' => remote_file_id,
        'thumbnail_id' => nil
      }
    end

    # Pull parent resource & set staged projects
    before do
      parent.pull
    end

    it 'can pull a snapshot of a new file' do
      file.pull
      expect(file_attributes).to include(expected_attributes)
      expect(snapshot_attributes).to include(expected_attributes)
    end

    it 'can pull a snapshot of an existing file' do
      file.pull
      file_sync.rename('my new file name')

      # Update file content for thumbnail
      Providers::GoogleDrive::ApiConnection
        .default.update_file_content(file_sync.id, 'new file content')
      sleep 5 if VCR.current_cassette.recording?

      file.reload.pull
      expected_attributes['name'] = 'my new file name'
      expected_attributes.delete('content_version')
      expected_attributes['thumbnail_id'] = VCS::FileThumbnail.first.id
      expect(file_attributes).to include(expected_attributes)
      expect(snapshot_attributes).to include(expected_attributes)
    end

    it 'can pull a snapshot of a removed file' do
      file.pull
      api.delete_file(file.remote_file_id)
      file.reload.pull
      expect(file_from_database).to be_deleted
      expect(file_from_database.current_snapshot).to be nil
    end
  end
end
