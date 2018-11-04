# frozen_string_literal: true

RSpec.describe VCS::Branch, type: :model do
  describe 'scope: where_staged_files_include_external_id' do
    subject { described_class.where_staged_files_include_external_id(ids) }
    let(:ids)     { [file1, file2, file3].map(&:external_id) }

    let!(:file1)  { create :vcs_staged_file }
    let!(:file2)  { create :vcs_staged_file }
    let!(:file3)  { create :vcs_staged_file }

    it { is_expected.to match_array [file1, file2, file3].map(&:branch) }

    context 'when one file is root' do
      let!(:file1) { create :vcs_staged_file, :root }

      it 'still includes the branch' do
        is_expected.to include(file1.branch)
      end
    end

    context 'when a branch has a multiple matches' do
      let!(:extra_match) { create :vcs_staged_file, branch: file1.branch }

      before { ids << extra_match.external_id }

      it 'returns the branch only once' do
        is_expected.to match_array [file1, file2, file3].map(&:branch)
      end
    end
  end
end
