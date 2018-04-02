# frozen_string_literal: true

require 'models/shared_examples/being_diffing.rb'

RSpec.describe FileDiff, type: :model do
  subject(:diff) { build_stubbed :file_diff }

  it_should_behave_like 'being diffing' do
    let(:diffing) do
      build_stubbed :file_diff,
                    current_snapshot: current_snapshot,
                    previous_snapshot: previous_snapshot
    end
    let(:current_snapshot)  { build_stubbed :file_resource_snapshot }
    let(:previous_snapshot) { build_stubbed :file_resource_snapshot }
  end

  describe 'associations' do
    it do
      is_expected
        .to belong_to(:revision)
        .autosave(false)
        .inverse_of(:file_diffs)
        .dependent(false)
    end
    it do
      is_expected.to belong_to(:file_resource).autosave(false).dependent(false)
    end
    it do
      is_expected
        .to belong_to(:current_snapshot)
        .class_name('FileResource::Snapshot')
        .dependent(false)
        .optional
    end
    it do
      is_expected
        .to belong_to(:previous_snapshot)
        .class_name('FileResource::Snapshot')
        .dependent(false)
        .optional
    end
  end

  describe 'delegations' do
    it { is_expected.to delegate_method(:committed_files).to(:revision) }
  end

  describe 'validations' do
    context 'when previous_snapshot_id is nil' do
      before  { diff.previous_snapshot_id = nil }
      it      { is_expected.to validate_presence_of(:current_snapshot_id) }
    end

    context 'when current_snapshot_id is nil' do
      before  { diff.current_snapshot_id = nil }
      it      { is_expected.to validate_presence_of(:previous_snapshot_id) }
    end
  end

  describe '#apply_selected_changes' do
    let(:diff1) { instance_double FileDiff }
    let(:diff2) { instance_double FileDiff }
    let(:change1) { instance_double FileDiff::Change }
    let(:change2) { instance_double FileDiff::Change }

    before do
      allow(diff).to receive(:changes).and_return [change1, change2]
      allow(change1).to receive(:selected?).and_return false
      allow(change2).to receive(:selected?).and_return false
      allow(change1).to receive(:apply)
      allow(change2).to receive(:apply)
      allow(diff).to receive(:persist_file_to_committed_files)
    end

    after { diff.send :apply_selected_changes }

    it 'calls apply_selected_changes on each file_diff' do
      expect(change1).to receive(:apply)
      expect(change2).to receive(:apply)
    end

    it 'persists file to committed files' do
      expect(diff).to receive(:persist_file_to_committed_files)
    end

    context 'when all changes are selected' do
      before do
        allow(change1).to receive(:selected?).and_return true
        allow(change2).to receive(:selected?).and_return true
      end

      it 'does not apply selected changes or persist file' do
        expect(change1).not_to receive(:apply)
        expect(change2).not_to receive(:apply)
        expect(diff).not_to receive(:persist_file_to_committed_files)
      end
    end
  end
end
