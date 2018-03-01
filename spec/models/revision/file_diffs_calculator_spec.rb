# frozen_string_literal: true

RSpec.describe Revision::FileDiffsCalculator, type: :model do
  subject(:calculator) { Revision::FileDiffsCalculator.new(revision: revision) }
  let(:revision)       { instance_double Revision }

  describe '#cache_diffs!' do
    before { allow(calculator).to receive(:diffs).and_return %w[d1 d2 d3] }

    it 'calls FileDiff.import' do
      expect(FileDiff).to receive(:import).with(%w[d1 d2 d3], validate: false)
      calculator.cache_diffs!
    end
  end

  describe '#diffs' do
    it 'calculates diffs' do
      expect(calculator).to receive(:calculate_diffs)
      calculator.diffs
    end
  end

  describe '#calculate_diffs' do
    subject(:method) { calculator.send :calculate_diffs }

    let(:raw_diffs) do
      [{ 'id' => 'raw1' }, { 'id' => 'raw2' }, { 'id' => 'raw3' }]
    end

    before do
      allow(calculator).to receive(:raw_diffs).and_return raw_diffs
      allow(calculator)
        .to receive(:raw_diff_to_diff)
        .with('id' => 'raw1')
        .and_return('id' => 'diff1')
      allow(calculator)
        .to receive(:raw_diff_to_diff)
        .with('id' => 'raw2')
        .and_return('id' => 'diff2')
      allow(calculator)
        .to receive(:raw_diff_to_diff)
        .with('id' => 'raw3')
        .and_return('id' => 'diff3')
    end

    it 'returns raw diffs converted to diffs' do
      is_expected.to contain_exactly(
        hash_including('id' => 'diff1'),
        hash_including('id' => 'diff2'),
        hash_including('id' => 'diff3')
      )
    end

    it 'adds first_three_ancestors' do
      is_expected.to contain_exactly(
        hash_including('first_three_ancestors' => []),
        hash_including('first_three_ancestors' => []),
        hash_including('first_three_ancestors' => [])
      )
    end
  end

  describe '#raw_diff_to_diff(raw_diff)' do
    subject(:method) { calculator.send :raw_diff_to_diff, raw_diff }

    let(:raw_diff) do
      { 'file_resource_id' => 100,
        'snapshots' => [
          { 'revision_id' => 1, 'file_resource_snapshot_id' => 9 },
          { 'revision_id' => 2, 'file_resource_snapshot_id' => 21 }
        ] }
    end

    before do
      allow(revision).to receive(:id).and_return 'revision-id'
      allow(revision).to receive(:parent_id).and_return 'parent-revision-id'
      allow(calculator)
        .to receive(:snapshot_id_from_raw_diff)
        .with(raw_diff, 'revision-id')
        .and_return('current-snapshot-id')
      allow(calculator)
        .to receive(:snapshot_id_from_raw_diff)
        .with(raw_diff, 'parent-revision-id')
        .and_return('previous-snapshot-id')
    end

    it 'keeps file_resource_id' do
      is_expected.to include('file_resource_id' => 100)
    end

    it 'sets revision id' do
      is_expected.to include('revision_id' => 'revision-id')
    end

    it 'sets current snapshot id' do
      is_expected.to include('current_snapshot_id' => 'current-snapshot-id')
    end

    it 'sets previous snapshot id' do
      is_expected.to include('previous_snapshot_id' => 'previous-snapshot-id')
    end
  end

  describe '#snapshot_id_from_raw_diff(raw_diff, revision_id)' do
    subject(:method) do
      calculator.send :snapshot_id_from_raw_diff, raw_diff, revision_id
    end

    let(:raw_diff) do
      { 'file_resource_id' => 100,
        'snapshots' => [
          { 'revision_id' => 1, 'file_resource_snapshot_id' => 9 },
          { 'revision_id' => 2, 'file_resource_snapshot_id' => 21 }
        ] }
    end

    context 'when revision_id is 1' do
      let(:revision_id) { 1 }
      it { is_expected.to eq 9 }
    end

    context 'when revision_id is 2' do
      let(:revision_id) { 2 }
      it { is_expected.to eq 21 }
    end

    context 'when revision_id does not exist' do
      let(:revision_id) { 3 }
      it { is_expected.to eq nil }
    end
  end
end
