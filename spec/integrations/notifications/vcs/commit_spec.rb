# frozen_string_literal: true

RSpec.describe Notifications::VCS::Commit, type: :model do
  subject(:notification)  { described_class.new(revision) }
  let(:revision)          { create(:vcs_commit, :drafted, branch: branch) }
  let(:branch)            { create :vcs_branch }

  describe '#recipients' do
    subject(:recipients)  { notification.recipients }
    let(:author)          { revision.author }
    let(:project) do
      create :project, :skip_archive_setup, :with_repository,
             master_branch: branch
    end
    let(:owner)           { project.owner }
    let(:collaborator1)   { author }
    let(:collaborator2)   { create :user }
    let(:collaborator3)   { create :user }
    let(:collaborators)   { [collaborator1, collaborator2, collaborator3] }

    before { project.collaborators << collaborators }

    it 'returns owner and collaborators without revision author' do
      is_expected
        .to match_array [owner, collaborator2, collaborator3].map(&:account)
    end

    context 'when project has no collaborators' do
      let(:collaborators) { [] }

      it 'returns owner only' do
        is_expected.to contain_exactly owner.account
      end
    end
  end
end
