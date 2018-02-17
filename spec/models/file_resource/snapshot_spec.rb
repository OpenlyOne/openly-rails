# frozen_string_literal: true

RSpec.describe FileResource::Snapshot, type: :model do
  subject(:snapshot) { build :file_resource_snapshot }
  describe 'associations' do
    it do
      is_expected.to belong_to(:file_resource).validate(false).dependent(false)
    end
    it do
      is_expected
        .to belong_to(:parent).class_name('FileResource')
        .validate(false).dependent(false)
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:file_resource_id) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:content_version) }
    it { is_expected.to validate_presence_of(:mime_type) }
    it { is_expected.to validate_presence_of(:external_id) }

    context 'when snapshot with same attributes already exists' do
      subject(:duplicate_snapshot)  { described_class.new(snapshot.attributes) }
      let(:before_hook)             { nil }
      before { before_hook }
      before { snapshot.save }

      it { is_expected.to be_invalid }

      context 'when parent_id is nil' do
        let(:before_hook) { snapshot.parent = nil }

        it { is_expected.to be_invalid }
      end

      context 'when snapshot is not a new record' do
        before { allow(subject).to receive(:new_record?).and_return false }
        it { is_expected.to be_valid }
      end
    end
  end

  describe 'read-only instance' do
    context 'on create' do
      let(:snapshot) { build :file_resource_snapshot }
      it { expect { snapshot.save }.not_to raise_error }
    end

    context 'on update' do
      let(:snapshot) { create :file_resource_snapshot }
      it do
        expect { snapshot.save }.to raise_error ActiveRecord::ReadOnlyRecord
      end
    end

    context 'on destroy' do
      let(:snapshot) { create :file_resource_snapshot }
      it { expect { snapshot.destroy }.not_to raise_error }
    end
  end
end
