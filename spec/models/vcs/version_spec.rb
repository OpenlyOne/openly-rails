# frozen_string_literal: true

require 'models/shared_examples/vcs/being_resourceable.rb'

RSpec.describe VCS::Version, type: :model do
  subject(:version) { build_stubbed :vcs_version }

  it_should_behave_like 'vcs: being resourceable' do
    let(:resourceable)    { version }
    let(:icon_class)      { Providers::GoogleDrive::Icon }
    let(:link_class)      { Providers::GoogleDrive::Link }
    let(:mime_type_class) { Providers::GoogleDrive::MimeType }
  end

  describe 'associations' do
    it do
      is_expected.to belong_to(:file).validate(false).dependent(false)
    end
    it do
      is_expected
        .to belong_to(:parent)
        .class_name('VCS::File')
        .validate(false)
        .dependent(false)
        .optional
    end
    it { is_expected.to belong_to(:content) }
    it do
      is_expected
        .to have_one(:backup)
        .class_name('VCS::FileBackup')
        .inverse_of(:file_version)
        .dependent(:destroy)
    end
    it { is_expected.to have_one(:repository).through(:file) }
  end

  describe 'attributes' do
    it { is_expected.to respond_to(:versionable_id) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:file_id) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:content_version) }
    it { is_expected.to validate_presence_of(:mime_type) }
    it { is_expected.to validate_presence_of(:remote_file_id) }
    it do
      is_expected.to validate_presence_of(:content).with_message('must exist')
    end

    context 'uniqueness validation' do
      subject(:version) { build :vcs_version }
      it do
        is_expected
          .to validate_uniqueness_of(:file_id)
          .scoped_to(:name, :content_id, :mime_type, :parent_id)
          .with_message('already has a version with these attributes')
      end
    end
  end

  describe 'read-only instance' do
    context 'on create' do
      let(:version) { build :vcs_version }
      it { expect { version.save }.not_to raise_error }
    end

    context 'on update' do
      let(:version) { create :vcs_version }
      it do
        expect { version.save }.to raise_error ActiveRecord::ReadOnlyRecord
      end
    end

    context 'on destroy' do
      let(:version) { create :vcs_version }
      it { expect { version.destroy }.not_to raise_error }
    end
  end

  describe '.for(attributes)' do
    subject { described_class.for('attributes') }

    before do
      allow(described_class)
        .to receive(:find_or_create_by_attributes)
        .with('core', 'supplemental')
        .and_return 'new-version'
      allow(described_class)
        .to receive(:core_attributes).with('attributes').and_return 'core'
      allow(described_class)
        .to receive(:supplemental_attributes)
        .with('attributes')
        .and_return 'supplemental'
    end

    it { is_expected.to eq 'new-version' }
  end

  describe '.find_or_create_by_attributes(core, supplements)' do
    subject { described_class.find_or_create_by_attributes('core', 'suppl') }
    let(:new_version) { instance_double described_class }

    before do
      chain = class_double described_class
      allow(described_class)
        .to receive(:create_with)
        .with('suppl')
        .and_return chain
      allow(chain)
        .to receive(:find_or_create_by!).with('core').and_return new_version
      allow(new_version)
        .to receive(:update_supplemental_attributes).with('suppl')
    end

    it { is_expected.to eq new_version }
  end

  describe '#plain_text_content' do
    subject(:plain_text) { version.plain_text_content }

    let(:content) { instance_double VCS::Content }

    before do
      allow(version).to receive(:content).and_return content
      allow(content).to receive(:plain_text).and_return 'plain' if content
    end

    it { is_expected.to eq 'plain' }

    context 'when content is nil' do
      let(:content) { nil }

      it { is_expected.to be nil }
    end
  end

  describe '#hashed_file_id' do
    subject(:hashed_file_id) { version.hashed_file_id }

    before do
      allow(version).to receive(:file_id).and_return 'file-id'
      allow(VCS::File).to receive(:id_to_hashid).and_return 'hashed-id'
    end

    it 'calls .id_to_hashid on VCS::File' do
      is_expected.to eq 'hashed-id'
      expect(VCS::File).to have_received(:id_to_hashid).with('file-id')
    end
  end

  describe '#version!' do
    subject           { version.version! }
    let(:new_version) { instance_double described_class }

    before do
      allow(VCS::Version)
        .to receive(:for).with('attributes').and_return new_version
      allow(new_version).to receive(:id).and_return 'new-id'
      allow(version).to receive(:attributes).and_return 'attributes'
      allow(version).to receive(:id=)
      allow(version).to receive(:reload)
    end

    after { subject }

    it 'sets ID to new version' do
      expect(version).to receive(:id=).with('new-id')
    end

    it 'calls #reload' do
      expect(version).to receive(:reload)
    end
  end

  describe '#update_supplemental_version_attributes' do
    let(:new_attributes)      { { a: 1, b: 2, c: 3 } }
    let(:current_attributes)  { { c: 3, a: 2 } }

    before do
      allow(version)
        .to receive(:supplemental_attributes).and_return current_attributes
    end

    after { version.update_supplemental_attributes(new_attributes) }
    it    { is_expected.to receive(:update_columns).with(a: 1, b: 2) }

    context 'when all supplemental attributes are up to date' do
      let(:current_attributes) { new_attributes }
      it { is_expected.not_to receive(:update_columns) }
    end
  end
end
