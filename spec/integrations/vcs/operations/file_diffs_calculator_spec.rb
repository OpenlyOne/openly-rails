# frozen_string_literal: true

RSpec.describe VCS::Operations::FileDiffsCalculator, type: :model do
  subject(:calculator)  { described_class.new(commit: commit) }
  let(:commit)          { create :vcs_commit, :with_parent }
  let(:parent_commit)   { commit.parent }

  describe '#cache_diffs!' do
    let(:diffs) { VCS::FileDiff.where(commit: commit) }
    let(:diff1) { diffs.where_file_record_id(f1.file_record_id).first }
    let(:diff2) { diffs.where_file_record_id(f2.file_record_id).first }
    let(:diff3) { diffs.where_file_record_id(f3.file_record_id).first }
    let(:diff4) { diffs.where_file_record_id(f4.file_record_id).first }
    let(:diff5) { diffs.where_file_record_id(f5.file_record_id).first }
    let(:diff6) { diffs.where_file_record_id(f6.file_record_id).first }
    let(:diff7) { diffs.where_file_record_id(f7.file_record_id).first }
    let(:diff8) { diffs.where_file_record_id(f8.file_record_id).first }
    let(:diff9) { diffs.where_file_record_id(f9.file_record_id).first }

    let(:f1) { create :vcs_file_snapshot, name: 'f1' }
    let(:f2) { create :vcs_file_snapshot, name: 'f2', parent: f1 }
    let(:f3) { create :vcs_file_snapshot, name: 'f3', parent: f2 }
    let(:f4) { create :vcs_file_snapshot, name: 'f4', parent: f3 }
    let(:f5) { create :vcs_file_snapshot, name: 'f5', parent: f4 }
    let(:f6) { create :vcs_file_snapshot, name: 'f6' }
    let(:f7) { create :vcs_file_snapshot, name: 'f7', parent: f6 }
    let(:f8) { create :vcs_file_snapshot, name: 'f8', parent: f2 }
    let(:f9) { create :vcs_file_snapshot, name: 'f9', parent: f8 }

    before do
      # committed files in parent commit
      [f1, f2, f3, f4, f5, f6, f7].each do |file|
        create :vcs_committed_file, commit: parent_commit, file_snapshot: file
      end

      # update parents of f3 and f6
      f3.assign_attributes(file_record_parent: f6.file_record)
      f3.snapshot!
      f6.assign_attributes(file_record_parent: f2.file_record)
      f6.snapshot!

      # committed files in current commit
      [f1, f2, f3, f6, f7, f8, f9].each do |file|
        create :vcs_committed_file, commit: commit, file_snapshot: file
      end

      # calculate and cache diffs!
      calculator.cache_diffs!
    end

    it 'has diffs for f3, f4, f5, f6, f8, f9' do
      expect(diffs.with_file_record_id.map(&:file_record_id))
        .to match_array [f3, f4, f5, f6, f8, f9].map(&:file_record_id)

      expect(diff3).to be_update
      expect(diff3.first_three_ancestors).to eq %w[f6 f2 f1]

      expect(diff4).to be_deletion
      expect(diff4.first_three_ancestors).to eq %w[f3 f6 f2]

      expect(diff5).to be_deletion
      expect(diff5.first_three_ancestors).to eq %w[f4 f3 f6]

      expect(diff8).to be_addition
      expect(diff8.first_three_ancestors).to eq %w[f2 f1]

      expect(diff9).to be_addition
      expect(diff9.first_three_ancestors).to eq %w[f8 f2 f1]
    end

    context 'when revision is origin revision (parent is nil)' do
      let(:commit)        { create :vcs_commit }
      let(:parent_commit) { create :vcs_commit }

      it 'has diffs for f1, f2, f3, f6, f7, f8, f9' do
        expect(diffs.with_file_record_id.map(&:file_record_id))
          .to match_array [f1, f2, f3, f6, f7, f8, f9].map(&:file_record_id)

        expect(diff1).to be_addition
        expect(diff1.first_three_ancestors).to eq %w[]

        expect(diff2).to be_addition
        expect(diff2.first_three_ancestors).to eq %w[f1]

        expect(diff3).to be_addition
        expect(diff3.first_three_ancestors).to eq %w[f6 f2 f1]

        expect(diff6).to be_addition
        expect(diff6.first_three_ancestors).to eq %w[f2 f1]

        expect(diff7).to be_addition
        expect(diff7.first_three_ancestors).to eq %w[f6 f2 f1]

        expect(diff8).to be_addition
        expect(diff8.first_three_ancestors).to eq %w[f2 f1]

        expect(diff9).to be_addition
        expect(diff9.first_three_ancestors).to eq %w[f8 f2 f1]
      end
    end
  end
end
