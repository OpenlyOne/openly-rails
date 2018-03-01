# frozen_string_literal: true

RSpec.describe Revision::FileDiffsCalculator, type: :model do
  subject(:calculator)  { described_class.new(revision: revision) }
  let(:revision)        { create :revision, :with_parent }
  let(:parent_revision) { revision.parent }

  describe '#cache_diffs!' do
    let(:diffs) { FileDiff.where(revision: revision) }
    let(:diff1) { diffs.find_by(file_resource_id: f1.id) }
    let(:diff2) { diffs.find_by(file_resource_id: f2.id) }
    let(:diff3) { diffs.find_by(file_resource_id: f3.id) }
    let(:diff4) { diffs.find_by(file_resource_id: f4.id) }
    let(:diff5) { diffs.find_by(file_resource_id: f5.id) }
    let(:diff6) { diffs.find_by(file_resource_id: f6.id) }
    let(:diff7) { diffs.find_by(file_resource_id: f7.id) }
    let(:diff8) { diffs.find_by(file_resource_id: f8.id) }
    let(:diff9) { diffs.find_by(file_resource_id: f9.id) }

    let(:f1) { create :file_resource, name: 'f1' }
    let(:f2) { create :file_resource, name: 'f2', parent: f1 }
    let(:f3) { create :file_resource, name: 'f3', parent: f2 }
    let(:f4) { create :file_resource, name: 'f4', parent: f3 }
    let(:f5) { create :file_resource, name: 'f5', parent: f4 }
    let(:f6) { create :file_resource, name: 'f6' }
    let(:f7) { create :file_resource, name: 'f7', parent: f6 }
    let(:f8) { create :file_resource, name: 'f8', parent: f2 }
    let(:f9) { create :file_resource, name: 'f9', parent: f8 }

    before do
      # committed files in parent revision
      [f1, f2, f3, f4, f5, f6, f7].each do |file|
        create :committed_file, revision: parent_revision, file_resource: file
      end

      # update parents of f3 and f6
      f3.update!(parent: f6)
      f6.update!(parent: f2)

      # committed files in current revision
      [f1, f2, f3, f6, f7, f8, f9].each do |file|
        create :committed_file, revision: revision, file_resource: file
      end

      # calculate and cache diffs!
      calculator.cache_diffs!
    end

    it 'has diffs for f3, f4, f5, f6, f8, f9' do
      expect(diffs.map(&:file_resource_id))
        .to match_array [f3, f4, f5, f6, f8, f9].map(&:id)

      expect(diff3).to be_updated
      expect(diff4).to be_deleted
      expect(diff5).to be_deleted
      expect(diff8).to be_added
      expect(diff9).to be_added
    end

    context 'when revision is origin revision (parent is nil)' do
      let(:revision)        { create :revision }
      let(:parent_revision) { create :revision }

      it 'has diffs for f1, f2, f3, f6, f7, f8, f9' do
        expect(diffs.map(&:file_resource_id))
          .to match_array [f1, f2, f3, f6, f7, f8, f9].map(&:id)

        expect(diff1).to be_added
        expect(diff2).to be_added
        expect(diff3).to be_added
        expect(diff6).to be_added
        expect(diff7).to be_added
        expect(diff8).to be_added
        expect(diff9).to be_added
      end
    end
  end
end
