# frozen_string_literal: true

RSpec.shared_examples 'being a file resource' do
  subject { file_resource }

  describe 'associations' do
    it do
      is_expected
        .to belong_to(:parent)
        .class_name(described_class.model_name.to_s)
        .dependent(false)
    end
    it do
      is_expected
        .to have_many(:children)
        .class_name(described_class.model_name.to_s)
        .inverse_of(:parent)
        .with_foreign_key(:parent_id)
        .dependent(false)
    end
  end

  describe 'attributes' do
    it { is_expected.to have_readonly_attribute(:provider_id) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:provider_id) }
    it { is_expected.to validate_presence_of(:external_id) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:mime_type) }
    it { is_expected.to validate_presence_of(:content_version) }
    it do
      is_expected
        .to validate_uniqueness_of(:external_id).scoped_to(:provider_id)
    end

    context 'when external id has not changed' do
      before do
        allow(file_resource).to receive(:external_id_changed?).and_return false
      end

      it { expect(file_resource).not_to validate_uniqueness_of(:external_id) }
    end

    context 'when parent association is loaded' do
      before  { file_resource.build_parent }
      after   { file_resource.valid? }

      it { expect(file_resource.parent).to receive(:valid?) }
      it { expect(file_resource).to receive(:cannot_be_its_own_parent) }
    end

    context 'when parent id has changed' do
      before  { file_resource.parent_id = 5 }
      after   { file_resource.valid? }

      it { expect(file_resource).to receive(:cannot_be_its_own_ancestor) }
    end

    context 'when file is deleted' do
      before { allow(file_resource).to receive(:deleted?).and_return true }

      it { is_expected.not_to validate_presence_of(:name) }
      it { is_expected.not_to validate_presence_of(:mime_type) }
      it { is_expected.not_to validate_presence_of(:content_version) }
    end
  end

  describe 'type casting' do
    subject(:file_from_db) { FileResource.find(file.id) }
    before { file.save! }
    it { expect(file_from_db).to be_an_instance_of described_class }
  end

  describe '#deleted?' do
    subject(:deleted) { file_resource.deleted? }

    it { is_expected.to be false }

    context 'when is_deleted = true' do
      before { allow(file_resource).to receive(:is_deleted).and_return true }

      it { is_expected.to be true }
    end
  end

  describe '#ancestors' do
    subject(:ancestors) { file_resource.ancestors }
    let(:file_from_db)  { described_class.find(file_resource.id) }

    before { file_resource.save }

    it { is_expected.to eq [] }

    context 'when file has many ancestors' do
      let(:grandgrandparent) do
        described_class.create!(attributes.merge(external_id: 'ggparent'))
      end
      let(:grandparent) do
        described_class.create!(attributes.merge(external_id: 'gparent'))
      end
      let(:parent) do
        described_class.create!(attributes.merge(external_id: 'parent'))
      end
      let(:attributes) do
        file_resource.dup.attributes.except('id', 'current_snapshot_id')
      end

      before do
        file_resource.update(parent: parent)
        parent.update(parent: grandparent)
        grandparent.update(parent: grandgrandparent)
      end

      it { is_expected.to eq [parent, grandparent, grandgrandparent] }
    end
  end

  describe '#ancestors_ids' do
    subject(:ancestors_ids) { file_resource.ancestors_ids }
    let(:ancestors)         { [] }

    before do
      allow(file_resource).to receive(:ancestors).and_return ancestors
    end

    it { is_expected.to eq [] }

    context 'when file has many ancestors' do
      let(:ancestors)         { [parent, grandparent, grandgrandparent] }
      let(:grandgrandparent)  { instance_double described_class }
      let(:grandparent)       { instance_double described_class }
      let(:parent)            { instance_double described_class }

      before do
        allow(grandgrandparent).to receive(:id).and_return 'ggparent'
        allow(grandparent).to receive(:id).and_return 'gparent'
        allow(parent).to receive(:id).and_return 'parent'
      end

      it { is_expected.to eq %w[parent gparent ggparent] }
    end
  end

  describe '#folder?' do
    subject(:folder_check) { file_resource.folder? }
    before do
      allow(file_resource).to receive(:mime_type).and_return 'mime-type'
      allow(mime_type_class)
        .to receive(:folder?).with('mime-type').and_return is_folder
    end

    context 'when mime type is a folder' do
      let(:is_folder) { true }
      it { is_expected.to be true }
    end

    context 'when mime type is not a folder' do
      let(:is_folder) { false }
      it { is_expected.to be false }
    end
  end

  describe '#subfolders' do
    subject(:subfolders)  { file_resource.subfolders }
    let(:folder1)         { instance_double described_class }
    let(:folder2)         { instance_double described_class }
    let(:file1)           { instance_double described_class }
    let(:file2)           { instance_double described_class }

    before do
      allow(file_resource)
        .to receive(:children).and_return [file1, folder1, file2, folder2]

      allow(folder1).to receive(:folder?).and_return true
      allow(folder2).to receive(:folder?).and_return true
      allow(file1).to receive(:folder?).and_return false
      allow(file2).to receive(:folder?).and_return false
    end

    it { is_expected.to contain_exactly folder1, folder2 }
  end

  describe '#cannot_be_its_own_ancestor' do
    subject(:validation)  { file_resource.send :cannot_be_its_own_ancestor }
    let(:ancestors_ids)   { [] }

    before do
      file_resource.save
      allow(file_resource).to receive(:ancestors_ids).and_return ancestors_ids
      validation
    end

    it { expect(file_resource.errors).to be_none }

    context 'when file is its own ancestor' do
      let(:ancestors_ids) { [file_resource.id] }
      it { expect(file_resource.errors).to be_one }
    end
  end

  describe '#cannot_be_its_own_parent' do
    subject(:validation)  { file_resource.send :cannot_be_its_own_parent }
    let(:parent)          { nil }

    before { file_resource.parent = parent }
    before { validation }

    it { expect(file_resource.errors).to be_none }

    context 'when file is its own parent' do
      let(:parent) { file_resource }
      it { expect(file_resource.errors).to be_one }
    end
  end
end
