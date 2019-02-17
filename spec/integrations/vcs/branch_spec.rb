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

  describe '#mark_files_as_committed(commit)' do
    subject(:mark_files) { branch.mark_files_as_committed(commit) }

    let(:commit) { create :vcs_commit }
    let(:files_in_branch) { create_list :vcs_file_in_branch, 3, branch: branch }
    let!(:committed_files) do
      files_in_branch.map do |file_in_branch|
        create :vcs_committed_file,
               version: create(:vcs_version, file: file_in_branch.file),
               commit: commit
      end
    end

    it 'sets correct committed_version_id on files' do
      mark_files
      expect(
        branch.files.reload.map { |f| [f.file_id, f.committed_version_id] }
      ).to match_array(
        committed_files.map { |c| [c.version.file_id, c.version_id] }
      )
    end

    context 'when untracked files exist in commit' do
      let!(:untracked_committed_files) do
        create_list :vcs_committed_file, 2, commit: commit
      end

      it 'copies files over to branch with correct version id' do
        mark_files
        expect(branch.files.count).to eq 5
        expect(
          branch.files.reload.map { |f| [f.file_id, f.committed_version_id] }
        ).to include(
          *untracked_committed_files
            .map { |c| [c.version.file_id, c.version_id] }
        )
      end

      it 'marks all copied files as deleted' do
        mark_files
        expect(
          branch.files.where(
            committed_version_id: untracked_committed_files.map(&:version_id)
          )
        ).to all(be_deleted)
      end
    end
  end

  describe '#update_uncaptured_changes_count' do
    subject(:update_count) { branch.update_uncaptured_changes_count }

    let!(:unchanged_in_branch) do
      create_list :vcs_file_in_branch, 2, :unchanged, branch: branch
    end
    let!(:changed_in_branch) do
      create_list :vcs_file_in_branch, 2, :changed, branch: branch
    end

    it { is_expected.to be true }

    it 'updates the uncaptured_changes_count on instance and in database' do
      update_count
      expect(branch.uncaptured_changes_count).to eq 2
      expect(branch.reload.uncaptured_changes_count).to eq 2
    end

    context 'when other branches have changed files' do
      let(:changed_files_in_other_branch) { create_list :vcs_file_in_branch, 2 }

      it 'does not change the count' do
        branch.update_uncaptured_changes_count
        expect { changed_files_in_other_branch && update_count }
          .not_to change(branch, :uncaptured_changes_count)
      end
    end

    context 'when root is unchanged' do
      let(:change_root) do
        create :vcs_file_in_branch, :unchanged, :root, branch: branch
      end

      it 'does not change the count' do
        branch.update_uncaptured_changes_count
        expect { change_root && update_count }
          .not_to change(branch, :uncaptured_changes_count)
      end
    end
  end
end
