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
end
