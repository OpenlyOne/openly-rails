# frozen_string_literal: true

RSpec.describe VCS::Repository, type: :model do
  subject(:repository) { create(:vcs_repository) }

  describe 'association: files#root' do
    subject { repository.files.root }

    context 'when root exists' do
      let(:branch) { create :vcs_branch, repository: repository }

      before { create :vcs_file_in_branch, :root, branch: branch }

      it { is_expected.to have_attributes(id: branch.root.file_id) }
    end

    context 'when root does not exist' do
      it { is_expected.to eq nil }
    end
  end
end
