# frozen_string_literal: true

RSpec.describe FileDiff, type: :model do
  subject(:diff) { build_stubbed :file_diff }

  describe 'associations' do
    it { is_expected.to belong_to(:revision).autosave(false).dependent(false) }
    it do
      is_expected.to belong_to(:file_resource).autosave(false).dependent(false)
    end
    it do
      is_expected
        .to belong_to(:current_snapshot)
        .class_name('FileResource::Snapshot')
        .dependent(false)
    end
    it do
      is_expected
        .to belong_to(:previous_snapshot)
        .class_name('FileResource::Snapshot')
        .dependent(false)
    end
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

  describe '#added?' do
    before { diff.current_snapshot_id = 123 }
    before { diff.previous_snapshot_id = previous_snapshot_id }

    context 'when previous_snapshot_id is nil' do
      let(:previous_snapshot_id) { nil }
      it { is_expected.to be_added }
    end

    context 'when previous_snapshot_id is not nil' do
      let(:previous_snapshot_id) { 456 }
      it { is_expected.not_to be_added }
    end
  end

  describe '#updated?' do
    let(:is_added) { false }
    let(:is_deleted) { false }

    before do
      allow(diff).to receive(:added?).and_return is_added
      allow(diff).to receive(:deleted?).and_return is_deleted
    end

    it { is_expected.to be_updated }

    context 'when diff is added' do
      let(:is_added) { true }
      it { is_expected.not_to be_updated }
    end

    context 'when diff is deleted' do
      let(:is_deleted) { true }
      it { is_expected.not_to be_updated }
    end
  end

  describe '#deleted?' do
    before { diff.previous_snapshot_id = 123 }
    before { diff.current_snapshot_id = current_snapshot_id }

    context 'when current_snapshot_id is nil' do
      let(:current_snapshot_id) { nil }
      it { is_expected.to be_deleted }
    end

    context 'when current_snapshot_id is not nil' do
      let(:current_snapshot_id) { 456 }
      it { is_expected.not_to be_deleted }
    end
  end
end
