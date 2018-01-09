# frozen_string_literal: true

require 'models/shared_examples/version_control/repository_locking.rb'

RSpec.describe VersionControl::RevisionDiff, type: :model do
  let(:revision_diff) { VersionControl::RevisionDiff.new(base, differentiator) }
  let(:base)            { repository.stage }
  let(:differentiator)  { repository.revisions.last }
  let(:repository)      { build :repository }

  describe '#changed_files_as_diffs' do
    subject(:method)      { revision_diff.changed_files_as_diffs }

    # create files
    let!(:root)           { create :file, :root, repository: repository }
    let!(:folder)         { create :file, :folder, parent: root }
    let!(:modified_file)  { create :file, parent: folder }
    let!(:moved_file)     { create :file, parent: root }
    let!(:deleted_file)   { create :file, parent: root }

    # commit
    before                { create :revision, repository: repository }

    # make some changes
    let!(:added_file)     { create :file, :folder, parent: root }
    before                { modified_file.update modified_time: Time.zone.now }
    before                { moved_file.update parent_id: folder.id }
    before                { deleted_file.update parent_id: nil }

    # generate commit draft
    let(:base)            { repository.build_revision }

    it 'returns four FileDiffs' do
      expect(method.map(&:class).uniq).to eq [VersionControl::FileDiff]
      expect(method.count).to eq 4
    end

    it 'includes the added file' do
      expect(method.find(&:added?).id).to eq added_file.id
    end

    it 'includes the modified file' do
      expect(method.find(&:modified?).id).to eq modified_file.id
    end

    it 'includes the moved file' do
      expect(method.find(&:moved?).id).to eq moved_file.id
    end

    it 'includes the deleted file' do
      expect(method.find(&:deleted?).id).to eq deleted_file.id
    end

    context 'when base is a committed revision' do
      # initialize differentiator
      let!(:differentiator) { repository.revisions.last }
      # commit again & initialize base
      let(:base) { create :revision, repository: repository }

      it 'still returns four FileDiffs' do
        expect(method.map(&:class).uniq).to eq [VersionControl::FileDiff]
        expect(method.count).to eq 4
      end
    end

    context 'when differentiator is nil' do
      let(:differentiator) { nil }
      it 'marks all files as added' do
        expect(method).to be_all(&:added?)
        expect(method.count).to eq 4
      end
    end

    context 'when no files have changed' do
      # commit again & initialize differentiator
      let!(:differentiator) { create :revision, repository: repository }
      before { repository.revisions.reload }
      # commit again & initialize base
      let(:base) { create :revision, repository: repository }

      it { is_expected.to eq [] }
    end

    context 'when changed files include root' do
      before { root.update modified_time: Time.zone.now }

      it { expect(method.map(&:id)).not_to include root.id }
    end
  end
end
