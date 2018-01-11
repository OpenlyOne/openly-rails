# frozen_string_literal: true

RSpec.describe VersionControl::RevisionCollection, type: :model do
  subject(:revision_collection) { repository.revisions }
  let(:repository)              { build :repository }

  describe '#all' do
    subject(:method)        { revision_collection.all }
    let!(:oldest_revision)  { create :revision, repository: repository }
    let!(:second_revision)  { create :revision, repository: repository }
    let!(:newest_revision)  { create :revision, repository: repository }

    it 'returns all three revisions' do
      expect(method.map(&:id)).to contain_exactly(
        newest_revision.id, second_revision.id, oldest_revision.id
      )
    end

    it 'returns the newest revision as the first element in the array' do
      expect(method.first.id).to eq newest_revision.id
    end

    it 'returns the oldest revision as the last element in the array' do
      expect(method.last.id).to eq oldest_revision.id
    end

    context 'when no revisions exist' do
      let(:revision_collection) { build(:repository).revisions }

      it { is_expected.to eq [] }
    end
  end
end
