# frozen_string_literal: true

require 'models/shared_examples/being_resourceable.rb'

RSpec.describe FileResource::Snapshot, type: :model do
  subject(:snapshot) { build :file_resource_snapshot }

  it_should_behave_like 'being resourceable' do
    let(:resourceable) { snapshot }
    let(:icon_class)      { Providers::GoogleDrive::Icon }
    let(:link_class)      { Providers::GoogleDrive::Link }
    let(:mime_type_class) { Providers::GoogleDrive::MimeType }
  end

  describe 'associations' do
    it do
      is_expected.to belong_to(:file_resource).validate(false).dependent(false)
    end
    it do
      is_expected
        .to belong_to(:parent).class_name('FileResource')
        .validate(false).dependent(false)
    end
    it do
      is_expected
        .to have_many(:committing_files)
        .class_name('CommittedFile')
        .with_foreign_key(:file_resource_snapshot_id)
        .dependent(false)
    end
  end

  describe 'attributes' do
    it { is_expected.to respond_to(:snapshotable_id) }
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

  describe '#provider_id' do
    subject         { snapshot.provider_id }
    let(:preloaded) { 'preloaded-provider-id' }

    before do
      allow(snapshot)
        .to receive(:read_attribute).with('provider_id').and_return preloaded
    end

    it { is_expected.to eq 'preloaded-provider-id' }

    context 'when provider_id is not preloaded' do
      let(:preloaded) { nil }

      before do
        file_resource = instance_double FileResource
        allow(snapshot).to receive(:file_resource).and_return file_resource
        allow(file_resource).to receive(:provider_id).and_return 'provider-id'
      end

      it { is_expected.to eq 'provider-id' }
    end
  end
end
