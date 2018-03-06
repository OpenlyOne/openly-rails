# frozen_string_literal: true

RSpec.describe Stage::FileDiff::Ancestry, type: :model do
  subject(:ancestry) { described_class }

  describe '.for(file_resource_snapshot:, project:, depth: nil)' do
    subject do
      ancestry.for(file_resource_snapshot: 'snapshot', project: 'p')
    end
    let(:parent_in_stage)     { 'parent-in-stage' }
    let(:parent_in_revision)  { 'parent-in-revision' }

    before do
      allow(ancestry).to receive(:for).and_call_original
      allow(ancestry)
        .to receive(:parent_snapshot_in_stage)
        .with('snapshot', 'p')
        .and_return parent_in_stage
      allow(ancestry)
        .to receive(:parent_snapshot_in_last_revision)
        .with('snapshot', 'p')
        .and_return parent_in_revision
      allow(ancestry)
        .to receive(:for)
        .with(file_resource_snapshot: parent_in_stage, project: 'p', depth: -2)
        .and_return ['output_from_recursive_call1']
      allow(ancestry)
        .to receive(:for)
        .with(file_resource_snapshot: parent_in_revision, project: 'p',
              depth: -2)
        .and_return ['output_from_recursive_call2']
    end

    it { is_expected.to eq %w[parent-in-stage output_from_recursive_call1] }

    context 'when parent is not in stage' do
      let(:parent_in_stage) { nil }

      it do
        is_expected.to eq %w[parent-in-revision output_from_recursive_call2]
      end
    end

    context 'when parent is in neither stage nor revision' do
      let(:parent_in_stage) { nil }
      let(:parent_in_revision) { nil }

      it { is_expected.to eq [] }
    end

    context 'when depth is 0' do
      subject do
        ancestry.for(file_resource_snapshot: 's', project: 'p', depth: 0)
      end

      it { is_expected.to eq [] }
    end
  end
end
