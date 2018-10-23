# frozen_string_literal: true

require 'models/shared_examples/being_resourceable.rb'

RSpec.describe FileResource::Snapshot, type: :model do
  subject(:snapshot) { build_stubbed :file_resource_snapshot }

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
        .validate(false).dependent(false).optional
    end
    it do
      is_expected
        .to have_one(:backup)
        .class_name('FileResource::Backup')
        .dependent(:destroy)
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

    context 'uniqueness validation' do
      subject(:snapshot) { build :file_resource_snapshot }
      it do
        is_expected
          .to validate_uniqueness_of(:file_resource_id)
          .scoped_to(:external_id, :content_version, :mime_type, :name,
                     :parent_id)
          .with_message('already has a snapshot with these attributes')
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

  describe '.for(attributes)' do
    subject { described_class.for('attributes') }

    before do
      allow(described_class)
        .to receive(:find_or_create_by_attributes)
        .with('core', 'supplemental')
        .and_return 'new-snapshot'
      allow(described_class)
        .to receive(:core_attributes).with('attributes').and_return 'core'
      allow(described_class)
        .to receive(:supplemental_attributes)
        .with('attributes')
        .and_return 'supplemental'
    end

    it { is_expected.to eq 'new-snapshot' }
  end

  describe '.find_or_create_by_attributes(core, supplements)' do
    subject { described_class.find_or_create_by_attributes('core', 'suppl') }
    let(:new_snapshot) { instance_double described_class }

    before do
      chain = class_double described_class
      allow(described_class)
        .to receive(:create_with)
        .with('suppl')
        .and_return chain
      allow(chain)
        .to receive(:find_or_create_by!).with('core').and_return new_snapshot
      allow(new_snapshot)
        .to receive(:update_supplemental_attributes).with('suppl')
    end

    it { is_expected.to eq new_snapshot }
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

  describe '#snapshot!' do
    subject             { snapshot.snapshot! }
    let(:new_snapshot)  { instance_double described_class }

    before do
      allow(FileResource::Snapshot)
        .to receive(:for).with('attributes').and_return new_snapshot
      allow(new_snapshot).to receive(:id).and_return 'new-id'
      allow(snapshot).to receive(:attributes).and_return 'attributes'
      allow(snapshot).to receive(:id=)
      allow(snapshot).to receive(:reload)
    end

    after { subject }

    it 'sets ID to new snapshot' do
      expect(snapshot).to receive(:id=).with('new-id')
    end

    it 'calls #reload' do
      expect(snapshot).to receive(:reload)
    end
  end

  describe '#update_supplemental_snapshot_attributes' do
    let(:new_attributes)      { { a: 1, b: 2, c: 3 } }
    let(:current_attributes)  { { c: 3, a: 2 } }

    before do
      allow(snapshot)
        .to receive(:supplemental_attributes).and_return current_attributes
    end

    after { snapshot.update_supplemental_attributes(new_attributes) }
    it    { is_expected.to receive(:update_columns).with(a: 1, b: 2) }

    context 'when all supplemental attributes are up to date' do
      let(:current_attributes) { new_attributes }
      it { is_expected.not_to receive(:update_columns) }
    end
  end
end
