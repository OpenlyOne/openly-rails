# frozen_string_literal: true

RSpec.describe VCS::Operations::FileDiffsCalculator, type: :model do
  subject(:calculator)  { described_class.new(commit: commit) }
  let(:commit)          { instance_double VCS::Commit }

  before { allow(commit).to receive(:parent).and_return nil }

  describe '#cache_diffs!' do
    before { allow(calculator).to receive(:diffs).and_return %w[d1 d2 d3] }

    it 'calls FileDiff.import' do
      expect(VCS::FileDiff)
        .to receive(:import).with(%w[d1 d2 d3], validate: false)
      calculator.cache_diffs!
    end
  end

  describe '#diffs' do
    it 'calculates diffs' do
      expect(calculator).to receive(:calculate_diffs)
      calculator.diffs
    end
  end

  describe '#ancestor_depth' do
    subject(:depth) { calculator.send :ancestor_depth }
    it { is_expected.to eq 3 }
  end

  describe '#ancestors_names_for(diff)' do
    subject(:ancestors) { calculator.send :ancestors_names_for, diff }
    let(:diff)          { { 'file_id' => 1, 'x' => 'y' } }
    let(:ancestry_tree) { instance_double VCS::Operations::FileAncestryTree }

    before do
      allow(calculator).to receive(:ancestry_tree).and_return ancestry_tree
      allow(ancestry_tree)
        .to receive(:ancestors_names_for)
        .with(1, depth: 'depth')
        .and_return %w[ancestor1 ancestor2 ancestor3]
      allow(calculator).to receive(:ancestor_depth).and_return 'depth'
    end

    it { is_expected.to eq %w[ancestor1 ancestor2 ancestor3] }
  end

  describe '#ancestry_tree' do
    let(:raw_diffs) do
      [{ 'file_id' => 1, 'x' => 'y' },
       { 'file_id' => 2, 'x' => 'y' },
       { 'file_id' => 3, 'x' => 'y' }]
    end
    let(:parent_commit) { instance_double VCS::Commit }

    before do
      allow(commit).to receive(:parent).and_return parent_commit
      allow(calculator).to receive(:raw_diffs).and_return raw_diffs
      allow(calculator).to receive(:ancestor_depth).and_return 'depth'
    end

    it 'generates FileAncestryTree' do
      expect(VCS::Operations::FileAncestryTree)
        .to receive(:generate)
        .with(commit: commit, parent_commit: parent_commit,
              file_ids: [1, 2, 3], depth: 'depth')
      calculator.send :ancestry_tree
    end
  end

  describe '#calculate_diffs' do
    subject(:method) { calculator.send :calculate_diffs }

    let(:raw_diffs) do
      [{ 'id' => 'raw1' }, { 'id' => 'raw2' }, { 'id' => 'raw3' }]
    end

    before do
      allow(calculator).to receive(:raw_diffs).and_return raw_diffs
      allow(calculator).to receive(:raw_diff_to_diff) do |raw|
        raw.merge('id' => raw['id'].gsub('raw', 'diff'))
      end
      allow(calculator).to receive(:ancestors_names_for) do |raw|
        id = raw['id'].gsub('raw', '')
        %W[#{id}.1 #{id}.2 #{id}.3]
      end
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
        hash_including('first_three_ancestors' => %w[1.1 1.2 1.3]),
        hash_including('first_three_ancestors' => %w[2.1 2.2 2.3]),
        hash_including('first_three_ancestors' => %w[3.1 3.2 3.3])
      )
    end
  end

  describe '#raw_diff_to_diff(raw_diff)' do
    subject(:method) { calculator.send :raw_diff_to_diff, raw_diff }

    let(:raw_diff) do
      { 'file_id' => 100,
        'versions' => [
          { 'commit_id' => 1, 'version_id' => 9 },
          { 'commit_id' => 2, 'version_id' => 21 }
        ] }
    end

    before do
      parent_commit = instance_double VCS::Commit
      allow(commit).to receive(:id).and_return 'commit-id'
      allow(commit).to receive(:parent).and_return parent_commit
      allow(parent_commit).to receive(:id).and_return 'parent-commit-id'
      allow(calculator)
        .to receive(:version_id_from_raw_diff)
        .with(raw_diff, 'commit-id')
        .and_return('current-version-id')
      allow(calculator)
        .to receive(:version_id_from_raw_diff)
        .with(raw_diff, 'parent-commit-id')
        .and_return('previous-version-id')
    end

    it 'keeps file_resource_id' do
      is_expected.to include('file_id' => 100)
    end

    it 'sets commit id' do
      is_expected.to include('commit_id' => 'commit-id')
    end

    it 'sets new version id' do
      is_expected.to include('new_version_id' => 'current-version-id')
    end

    it 'sets old version id' do
      is_expected.to include('old_version_id' => 'previous-version-id')
    end
  end

  describe '#version_id_from_raw_diff(raw_diff, commit_id)' do
    subject(:method) do
      calculator.send :version_id_from_raw_diff, raw_diff, commit_id
    end

    let(:raw_diff) do
      { 'file_id' => 100,
        'versions' => [
          { 'commit_id' => 1, 'version_id' => 9 },
          { 'commit_id' => 2, 'version_id' => 21 }
        ] }
    end

    context 'when commit_id is 1' do
      let(:commit_id) { 1 }
      it { is_expected.to eq 9 }
    end

    context 'when commit_id is 2' do
      let(:commit_id) { 2 }
      it { is_expected.to eq 21 }
    end

    context 'when commit_id does not exist' do
      let(:commit_id) { 3 }
      it { is_expected.to eq nil }
    end
  end
end
