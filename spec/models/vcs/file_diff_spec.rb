# frozen_string_literal: true

require 'models/shared_examples/vcs/being_diffing.rb'

RSpec.describe VCS::FileDiff, type: :model do
  subject(:diff) { build_stubbed :vcs_file_diff }

  it_should_behave_like 'vcs: being diffing' do
    let(:diffing) do
      build_stubbed :vcs_file_diff,
                    new_snapshot: new_snapshot,
                    old_snapshot: old_snapshot
    end
    let(:new_snapshot)  { build_stubbed :vcs_file_snapshot }
    let(:old_snapshot)  { build_stubbed :vcs_file_snapshot }
  end

  describe 'associations' do
    it do
      is_expected.to belong_to(:commit).inverse_of(:file_diffs).dependent(false)
    end
    it do
      is_expected
        .to belong_to(:new_snapshot)
        .class_name('VCS::FileSnapshot')
        .dependent(false)
        .optional
    end
    it do
      is_expected
        .to belong_to(:old_snapshot)
        .class_name('VCS::FileSnapshot')
        .dependent(false)
        .optional
    end
  end

  describe 'delegations' do
    it { is_expected.to delegate_method(:committed_files).to(:commit) }
  end

  describe 'validations' do
    context 'when old_snapshot_id is nil' do
      before  { diff.old_snapshot_id = nil }
      it      { is_expected.to validate_presence_of(:new_snapshot_id) }
    end

    context 'when new_snapshot_id is nil' do
      before  { diff.new_snapshot_id = nil }
      it      { is_expected.to validate_presence_of(:old_snapshot_id) }
    end
  end

  describe '#apply_selected_changes' do
    let(:diff1) { instance_double VCS::FileDiff }
    let(:diff2) { instance_double VCS::FileDiff }
    let(:change1) { instance_double VCS::FileDiff::Change }
    let(:change2) { instance_double VCS::FileDiff::Change }

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
