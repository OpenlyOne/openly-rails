# frozen_string_literal: true

RSpec.describe VersionControl::RevisionCollection, type: :model do
  subject(:revision_collection) { repository.revisions }
  let(:repository)              { build :repository }

  describe '#all' do
    subject(:method)        { revision_collection.all }
    let!(:oldest_revision)  { create :git_revision, repository: repository }
    let!(:second_revision)  { create :git_revision, repository: repository }
    let!(:newest_revision)  { create :git_revision, repository: repository }

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

  describe '#all_as_diffs' do
    subject(:method)        { revision_collection.all_as_diffs }
    let!(:oldest_revision)  { create :git_revision, repository: repository }
    let!(:second_revision)  { create :git_revision, repository: repository }
    let!(:newest_revision)  { create :git_revision, repository: repository }

    it 'returns three revision diffs' do
      expect(method).to be_an Array
      expect(method.map(&:class).uniq).to eq [VersionControl::RevisionDiff]
    end

    it 'returns an array with diff between newest and second revision' do
      expect(method.first).to have_attributes(
        base_id: newest_revision.id,
        differentiator_id: second_revision.id
      )
    end

    it 'returns an array with diff between second and oldest revision' do
      expect(method.first).to have_attributes(
        base_id: newest_revision.id,
        differentiator_id: second_revision.id
      )
    end

    it 'returns an array with diff between oldest revision and nil' do
      expect(method.first).to have_attributes(
        base_id: newest_revision.id,
        differentiator_id: second_revision.id
      )
    end
  end
end
