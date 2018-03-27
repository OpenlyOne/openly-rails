# frozen_string_literal: true

RSpec.describe Notifications::Revision, type: :model do
  subject(:notification)  { described_class.new(revision) }
  let(:revision)          { create(:revision, :drafted) }

  describe '#recipients' do
    subject(:recipients)  { notification.recipients }
    let(:author)          { revision.author }
    let(:project)         { revision.project }
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
