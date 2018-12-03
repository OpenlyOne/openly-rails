# frozen_string_literal: true

require 'integrations/shared_examples/vcs/including_downloadable_integration.rb'
require 'integrations/shared_examples/vcs/including_versionable_integration.rb'
require 'integrations/shared_examples/vcs/including_syncable_integration.rb'

RSpec.describe VCS::FileInBranch, type: :model do
  subject(:file_in_branch) do
    described_class.new(
      remote_file_id: remote_file_id,
      branch: branch,
      file: file
    )
  end
  let(:branch)          { create :vcs_branch }
  let(:file)            { create :vcs_file }
  let(:remote_file_id)  { 'id' }

  it_should_behave_like 'vcs: including versionable integration' do
    let(:file_in_branch)          { build :vcs_file_in_branch }
    let(:versionable)             { file_in_branch }
    let(:versionable_model_name)  { 'VCS::FileInBranch' }
  end

  it_should_behave_like 'vcs: including syncable integration' do
    let(:api)       { Providers::GoogleDrive::ApiConnection.default }
    let(:syncable)  { file_in_branch }
    let(:parent_id) { google_drive_test_folder_id }
    let(:mime_type) { Providers::GoogleDrive::MimeType.document }
    let(:folder_mime_type)  { Providers::GoogleDrive::MimeType.folder }
    let(:file_sync_class)   { Providers::GoogleDrive::FileSync }

    before { prepare_google_drive_test }
    after  { tear_down_google_drive_test }

    let!(:root) do
      create(:vcs_file_in_branch, :root, :folder,
             branch: branch, remote_file_id: parent_id)
    end
  end

  it_should_behave_like 'vcs: including downloadable integration' do
    let(:downloadable)    { file_in_branch }
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
      create(:vcs_file_in_branch, :root, :folder,
             branch: branch, remote_file_id: parent_id)
    end
  end

  describe 'versionable + syncable', :vcr do
    before { prepare_google_drive_test }
    after  { tear_down_google_drive_test }
    let!(:file_sync) do
      Providers::GoogleDrive::FileSync.create(
        name: 'Test File',
        parent_id: google_drive_test_folder_id,
        mime_type: Providers::GoogleDrive::MimeType.document
      )
    end
    let!(:parent_in_branch) do
      described_class.new(
        remote_file_id: google_drive_test_folder_id,
        branch: branch,
        file: parent,
        is_root: true
      )
    end
    let(:parent)          { create :vcs_file }
    let(:projects)        { create_list :project, 3 }
    let(:api)             { Providers::GoogleDrive::ApiConnection.default }
    let(:remote_file_id)  { file_sync.id }
    let(:file_from_database) do
      described_class.find_by_remote_file_id!(remote_file_id)
    end
    let(:file_attributes)     { file_from_database.attributes }
    let(:version_attributes)  { file_from_database.current_version.attributes }
    let(:expected_attributes) do
      {
        'name' => 'Test File',
        'parent_id' => parent_in_branch.file_id,
        'content_version' => '1',
        'mime_type' => Providers::GoogleDrive::MimeType.document,
        'remote_file_id' => remote_file_id,
        'thumbnail_id' => nil
      }
    end

    # Pull parent resource
    before { parent_in_branch.pull }

    it 'can pull a version of a new file' do
      file_in_branch.pull
      expect(file_attributes).to include(expected_attributes)
      expect(version_attributes).to include(expected_attributes)
    end

    it 'can pull a version of an existing file' do
      file_in_branch.pull
      file_sync.rename('my new file name')

      # Update file content for thumbnail
      Providers::GoogleDrive::ApiConnection
        .default.update_file_content(file_sync.id, 'new file content')
      sleep 5 if VCR.current_cassette.recording?

      file_in_branch.reload.pull
      expected_attributes['name'] = 'my new file name'
      expected_attributes.delete('content_version')
      expected_attributes['thumbnail_id'] = VCS::FileThumbnail.first.id
      expect(file_attributes).to include(expected_attributes)
      expect(version_attributes).to include(expected_attributes)
    end

    it 'can pull a version of a removed file' do
      file_in_branch.pull
      api.delete_file(file_in_branch.remote_file_id)
      file_in_branch.reload.pull
      expect(file_from_database).to be_deleted
      expect(file_from_database.current_version).to be nil
    end
  end
end
