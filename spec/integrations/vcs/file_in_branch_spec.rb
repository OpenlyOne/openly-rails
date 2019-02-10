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

  describe '.where_change_is_uncaptured' do
    subject(:uncaptured) { described_class.where_change_is_uncaptured }

    let!(:unchanged)  { create_list :vcs_file_in_branch, 2, :unchanged }
    let!(:deleted)    { create_list :vcs_file_in_branch, 2, :deleted }

    let!(:added) { create_list :vcs_file_in_branch, 2 }
    let!(:committed_and_deleted) do
      create_list :vcs_file_in_branch, 2, :deleted, :with_committed_version
    end
    let!(:changed) { create_list :vcs_file_in_branch, 2, :with_versions }

    it 'returns added, deleted, and changed files' do
      is_expected.to match_array(added + committed_and_deleted + changed)
    end
  end

  describe '.committed' do
    subject { described_class.committed }

    let(:committed) do
      create :vcs_file_in_branch, :with_versions, current_version: nil
    end
    let(:committed_and_current) do
      create :vcs_file_in_branch, :with_versions
    end
    let(:uncommitted) do
      create :vcs_file_in_branch, :with_versions, committed_version: nil
    end

    it 'returns files that are committed' do
      is_expected.to include(committed)
    end

    it 'returns files that are committed and current' do
      is_expected.to include(committed_and_current)
    end

    it 'does not return files that are not committed' do
      is_expected.not_to include(uncommitted)
    end
  end

  describe '.find_by_hashed_file_id!(id)' do
    subject(:finding) { described_class.find_by_hashed_file_id!(id_to_find) }

    let(:id_to_find)      { file_in_branch.hashed_file_id }
    let!(:file_in_branch) { create :vcs_file_in_branch }

    it { is_expected.to eq file_in_branch }

    context 'when no match exists' do
      before { file_in_branch.destroy }

      it { expect { finding }.to raise_error ActiveRecord::RecordNotFound }
    end

    context 'when it is being chained' do
      subject(:finding) do
        described_class.none.find_by_hashed_file_id!(id_to_find)
      end

      it 'is applied within the scope of the chain' do
        expect { finding }.to raise_error ActiveRecord::RecordNotFound
      end
    end
  end

  describe '.find_by_hashed_file_id_or_remote_file_id!(id)' do
    subject(:finding) do
      described_class.find_by_hashed_file_id_or_remote_file_id!(id_to_find)
    end
    let!(:file_matching_hashed_file_id) { create :vcs_file_in_branch }
    let!(:file_matching_remote_file_id) do
      create :vcs_file_in_branch, remote_file_id: id_to_find
    end
    let(:id_to_find) { file_matching_hashed_file_id.hashed_file_id }

    context 'when only file with hashed file ID exists' do
      before { file_matching_remote_file_id.destroy }

      it { is_expected.to eq file_matching_hashed_file_id }
    end

    context 'when only file with remote file ID exists' do
      before { file_matching_hashed_file_id.destroy }

      it { is_expected.to eq file_matching_remote_file_id }
    end

    context 'when both files exists' do
      context 'when ID of hashed file ID match > remote file ID match' do
        before do
          file_matching_hashed_file_id.update_column(
            :id,
            file_matching_remote_file_id.id + 1
          )
        end

        it { is_expected.to eq file_matching_hashed_file_id }
      end

      context 'when ID of hashed file ID match < remote file ID match' do
        before do
          file_matching_hashed_file_id.update_column(
            :id,
            file_matching_remote_file_id.id - 1
          )
        end

        it { is_expected.to eq file_matching_hashed_file_id }
      end
    end

    context 'when no match exists' do
      before { described_class.destroy_all }

      it { expect { finding }.to raise_error ActiveRecord::RecordNotFound }
    end

    context 'when it is being chained' do
      subject(:finding) do
        described_class
          .none
          .find_by_hashed_file_id_or_remote_file_id!(id_to_find)
      end

      it 'is applied within the scope of the chain' do
        expect { finding }.to raise_error ActiveRecord::RecordNotFound
      end
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

    # Pull parent resource
    before { parent_in_branch.pull }

    it 'can pull a version of a new file' do
      file_in_branch.pull
      expect(file_attributes).to include(
        'name' => 'Test File',
        'parent_id' => parent_in_branch.file_id,
        'content_version' => '1',
        'mime_type' => Providers::GoogleDrive::MimeType.document,
        'remote_file_id' => remote_file_id,
        'thumbnail_id' => nil
      )
      expect(version_attributes).to include(
        'name' => 'Test File',
        'parent_id' => parent_in_branch.file_id,
        'content_id' => file_in_branch.content_id,
        'mime_type' => Providers::GoogleDrive::MimeType.document,
        'thumbnail_id' => nil
      )
    end

    it 'can pull a version of an existing file' do
      file_in_branch.pull
      file_sync.rename('my new file name')

      # Update file content for thumbnail
      Providers::GoogleDrive::ApiConnection
        .default.update_file_content(file_sync.id, 'new file content')
      sleep 5 if VCR.current_cassette.recording?

      file_in_branch.reload.pull
      expect(file_attributes).to include(
        'name' => 'my new file name',
        'parent_id' => parent_in_branch.file_id,
        'mime_type' => Providers::GoogleDrive::MimeType.document,
        'remote_file_id' => remote_file_id,
        'thumbnail_id' => VCS::Thumbnail.first.id
      )
      expect(version_attributes).to include(
        'name' => 'my new file name',
        'parent_id' => parent_in_branch.file_id,
        'mime_type' => Providers::GoogleDrive::MimeType.document,
        'thumbnail_id' => VCS::Thumbnail.first.id
      )
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
