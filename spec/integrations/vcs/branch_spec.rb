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
          current_snapshot_id: nil,
          committed_snapshot_id: nil
        )
      end

      it 'does not return branch' do
        is_expected.to be_empty
      end
    end
  end
end
