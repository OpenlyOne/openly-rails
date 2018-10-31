# frozen_string_literal: true

RSpec.describe VCS::Operations::FileAncestryTree, type: :model do
  describe '.generate(commit:, file_ids:, depth:)' do
    subject(:tree) do
      described_class.generate(
        commit: commit,
        file_record_ids: [f5.file_record_id],
        depth: 3
      )
    end
    let(:commit) { create :vcs_commit }
    let(:f1) { create :vcs_file_snapshot, name: 'f1' }
    let(:f2) do
      create :vcs_file_snapshot, name: 'f2', parent: f1
    end
    let(:f3) do
      create :vcs_file_snapshot, name: 'f3', parent: f2
    end
    let(:f4) do
      create :vcs_file_snapshot, name: 'f4', parent: f3
    end
    let(:f5) do
      create :vcs_file_snapshot, name: 'f5', parent: f4
    end

    before do
      # committed files in current revision
      [f1, f2, f3, f4, f5].each do |file|
        create :vcs_committed_file, commit: commit, file_snapshot: file
      end
    end

    it 'has ancestors names f4, f3, f2' do
      expect(tree.ancestors_names_for(f5.file_record_id, depth: 3))
        .to eq %w[f4 f3 f2]
    end
  end
end
