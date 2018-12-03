# frozen_string_literal: true

RSpec.describe VCS::Operations::FileDiffsCalculator, type: :model do
  subject(:calculator)  { described_class.new(commit: commit) }
  let(:commit)          { create :vcs_commit, :with_parent }
  let(:parent_commit)   { commit.parent }

  describe '#cache_diffs!' do
    let(:diffs) { VCS::FileDiff.where(commit: commit) }
    let(:diff1) { diffs.where_file_id(f1.file_id).first }
    let(:diff2) { diffs.where_file_id(f2.file_id).first }
    let(:diff3) { diffs.where_file_id(f3.file_id).first }
    let(:diff4) { diffs.where_file_id(f4.file_id).first }
    let(:diff5) { diffs.where_file_id(f5.file_id).first }
    let(:diff6) { diffs.where_file_id(f6.file_id).first }
    let(:diff7) { diffs.where_file_id(f7.file_id).first }
    let(:diff8) { diffs.where_file_id(f8.file_id).first }
    let(:diff9) { diffs.where_file_id(f9.file_id).first }

    let(:f1) { create :vcs_version, name: 'f1' }
    let(:f2) { create :vcs_version, name: 'f2', parent_in_branch: f1 }
    let(:f3) { create :vcs_version, name: 'f3', parent_in_branch: f2 }
    let(:f4) { create :vcs_version, name: 'f4', parent_in_branch: f3 }
    let(:f5) { create :vcs_version, name: 'f5', parent_in_branch: f4 }
    let(:f6) { create :vcs_version, name: 'f6' }
    let(:f7) { create :vcs_version, name: 'f7', parent_in_branch: f6 }
    let(:f8) { create :vcs_version, name: 'f8', parent_in_branch: f2 }
    let(:f9) { create :vcs_version, name: 'f9', parent_in_branch: f8 }

    before do
      # committed files in parent commit
      [f1, f2, f3, f4, f5, f6, f7].each do |file|
        create :vcs_committed_file, commit: parent_commit, version: file
      end

      # update parents of f3 and f6
      f3.assign_attributes(parent: f6.file)
      f3.version!
      f6.assign_attributes(parent: f2.file)
      f6.version!

      # committed files in current commit
      [f1, f2, f3, f6, f7, f8, f9].each do |file|
        create :vcs_committed_file, commit: commit, version: file
      end

      # calculate and cache diffs!
      calculator.cache_diffs!
    end

    it 'has diffs for f3, f4, f5, f6, f8, f9' do
      expect(diffs.with_file_id.map(&:file_id))
        .to match_array [f3, f4, f5, f6, f8, f9].map(&:file_id)

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
        expect(diffs.with_file_id.map(&:file_id))
          .to match_array [f1, f2, f3, f6, f7, f8, f9].map(&:file_id)

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
