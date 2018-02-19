# frozen_string_literal: true

RSpec.describe CommittedFile, type: :model do
  subject(:file) { build_stubbed :committed_file }

  describe 'associations' do
    it do
      is_expected.to belong_to(:revision).autosave(false).dependent(false)
    end
    it do
      is_expected.to belong_to(:file_resource).autosave(false).dependent(false)
    end
    it do
      is_expected
        .to belong_to(:file_resource_snapshot)
        .class_name('FileResource::Snapshot')
        .dependent(false)
    end
  end

  describe 'validations' do
    subject(:file) { build :committed_file }

    it do
      is_expected
        .to validate_uniqueness_of(:file_resource_id)
        .scoped_to(:revision_id)
        .with_message('already exists in this revision')
    end
  end

  describe 'read-only instance' do
    subject(:file)  { build :committed_file }
    let(:create)    { file.save }
    let(:update)    { create && file.update(updated_at: Time.zone.now) }
    let(:destroy)   { create && file.destroy }

    before { allow(file).to receive(:revision_published?).and_return published }

    context 'when revision is not published' do
      let(:published) { false }

      it { expect { create }.not_to raise_error }
      it { expect { update }.not_to raise_error }
      it { expect { destroy }.not_to raise_error }
    end

    context 'when revision is published' do
      let(:published) { true }

      it { expect { create }.to raise_error ActiveRecord::ReadOnlyRecord }
      it { expect { update }.to raise_error ActiveRecord::ReadOnlyRecord }
      it { expect { destroy }.to raise_error ActiveRecord::ReadOnlyRecord }
    end
  end
end
