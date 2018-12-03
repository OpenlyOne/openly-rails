# frozen_string_literal: true

RSpec.describe VCS::Operations::FileAncestryTree, type: :model do
  describe '.generate(commit:, file_ids:, depth:)' do
    subject(:tree) do
      described_class.generate(
        commit: commit,
        file_ids: [f5.file_id],
        depth: 3
      )
    end
    let(:commit) { create :vcs_commit }
    let(:f1) { create :vcs_version, name: 'f1' }
    let(:f2) do
      create :vcs_version, name: 'f2', parent_in_branch: f1
    end
    let(:f3) do
      create :vcs_version, name: 'f3', parent_in_branch: f2
    end
    let(:f4) do
      create :vcs_version, name: 'f4', parent_in_branch: f3
    end
    let(:f5) do
      create :vcs_version, name: 'f5', parent_in_branch: f4
    end

    before do
      # committed files in current revision
      [f1, f2, f3, f4, f5].each do |version|
        create :vcs_committed_file, commit: commit, version: version
      end
    end

    it 'has ancestors names f4, f3, f2' do
      expect(tree.ancestors_names_for(f5.file_id, depth: 3))
        .to eq %w[f4 f3 f2]
    end
  end
end
