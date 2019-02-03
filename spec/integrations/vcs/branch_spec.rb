# frozen_string_literal: true

RSpec.describe VCS::Branch, type: :model do
  subject(:branch) { create :vcs_branch }

  describe 'scope: where_files_include_remote_file_id' do
    subject { described_class.where_files_include_remote_file_id(ids) }
    let(:ids)     { [file1, file2, file3].map(&:remote_file_id) }

    let!(:file1)  { create :vcs_file_in_branch }
    let!(:file2)  { create :vcs_file_in_branch }
    let!(:file3)  { create :vcs_file_in_branch }

    it { is_expected.to match_array [file1, file2, file3].map(&:branch) }

    context 'when one file is root' do
      let!(:file1) { create :vcs_file_in_branch, :root }

      it 'still includes the branch' do
        is_expected.to include(file1.branch)
      end
    end

    context 'when a branch has a multiple matches' do
      let!(:extra_match) { create :vcs_file_in_branch, branch: file1.branch }

      before { ids << extra_match.remote_file_id }

      it 'returns the branch only once' do
        is_expected.to match_array [file1, file2, file3].map(&:branch)
      end
    end

    context 'when branch includes removed files that match' do
      before do
        VCS::FileInBranch.update_all(
          current_version_id: nil,
          committed_version_id: nil
        )
      end

      it 'does not return branch' do
        is_expected.to be_empty
      end
    end
  end

  describe '#create_remote_root_folder' do
    subject(:create_remote_root_folder) do
      branch.create_remote_root_folder(remote_parent_id: remote_parent_id)
    end

    let(:branch) { create :vcs_branch }

    context 'when root folder does not exist', :vcr do
      let(:remote_parent_id) { google_drive_test_folder_id }

      before { prepare_google_drive_test }

      it 'creates remote and local folder' do
        create_remote_root_folder

        expect(branch.root).to be_present
        expect(branch.root).not_to be_deleted
        external_root =
          Providers::GoogleDrive::FileSync.new(branch.root.remote_file_id)
        expect(external_root.name).to start_with 'Branch #'
      end
    end

    context 'when root folder already exists' do
      let(:remote_parent_id) { 'some-id' }

      before { create :vcs_file_in_branch, :root, branch: branch }

      it { is_expected.to be false }
    end
  end

  describe '#copy_committed_files_from(branch_to_copy_from)' do
    subject(:copy) { branch.copy_committed_files_from(branch_to_copy_from) }

    let(:branch_to_copy_from) { create :vcs_branch }
    let!(:committed_files) do
      create_list :vcs_file_in_branch, 5, :with_versions,
                  current_version: nil, branch: branch_to_copy_from
    end
    let!(:uncommitted_files) do
      create_list :vcs_file_in_branch, 2, :with_versions,
                  committed_version: nil, branch: branch_to_copy_from
    end

    it 'copies only committed files' do
      copy
      expect(branch.files.map(&:committed_version_id))
        .to match_array(committed_files.map(&:committed_version_id))
    end

    it 'marks all copied files as deleted' do
      copy
      expect(branch.files).to all(be_deleted)
    end
  end
end
