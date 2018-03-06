# frozen_string_literal: true

RSpec.describe Revision::FileAncestryTree, type: :model do
  describe '.generate(revision:, file_ids:, depth:)' do
    subject(:tree) do
      described_class.generate(revision: revision, file_ids: [f5.id], depth: 3)
    end
    let(:revision) { create :revision }
    let(:f1) { create :file_resource, name: 'f1' }
    let(:f2) { create :file_resource, name: 'f2', parent: f1 }
    let(:f3) { create :file_resource, name: 'f3', parent: f2 }
    let(:f4) { create :file_resource, name: 'f4', parent: f3 }
    let(:f5) { create :file_resource, name: 'f5', parent: f4 }

    before do
      # committed files in current revision
      [f1, f2, f3, f4, f5].each do |file|
        create :committed_file, revision: revision, file_resource: file
      end
    end

    it 'has ancestors names f4, f3, f2' do
      expect(tree.ancestors_names_for(f5.id, depth: 3))
        .to eq %w[f4 f3 f2]
    end
  end
end
