# frozen_string_literal: true

RSpec.describe VCS::Branch, type: :model do
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
    subject(:create_remote_root_folder) { branch.create_remote_root_folder }

    let(:branch) { create :vcs_branch }

    context 'when root folder does not exist', :vcr do
      before { refresh_google_drive_authorization }

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
      before { create :vcs_file_in_branch, :root, branch: branch }

      it { is_expected.to be false }
    end
  end
end
