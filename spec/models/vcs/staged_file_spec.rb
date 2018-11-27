# frozen_string_literal: true

require 'models/shared_examples/vcs/being_backupable.rb'
require 'models/shared_examples/vcs/being_resourceable.rb'
require 'models/shared_examples/vcs/being_snapshotable.rb'
require 'models/shared_examples/vcs/being_syncable.rb'

RSpec.describe VCS::StagedFile, type: :model do
  subject(:staged_file) { build :vcs_staged_file }

  it_should_behave_like 'vcs: being backupable' do
    let(:backupable) { staged_file }
  end

  it_should_behave_like 'vcs: being resourceable' do
    let(:resourceable)    { staged_file }
    let(:icon_class)      { Providers::GoogleDrive::Icon }
    let(:link_class)      { Providers::GoogleDrive::Link }
    let(:mime_type_class) { Providers::GoogleDrive::MimeType }
  end

  it_should_behave_like 'vcs: being snapshotable' do
    let(:snapshotable) { staged_file }
    before { allow(staged_file).to receive(:backup_on_save?).and_return false }
  end

  it_should_behave_like 'vcs: being syncable' do
    let(:syncable) { staged_file }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:branch).dependent(false) }
    it { is_expected.to belong_to(:file_record).dependent(false) }
    it do
      is_expected
        .to belong_to(:file_record_parent)
        .class_name('VCS::FileRecord')
        .dependent(false)
        .optional
    end
    it do
      is_expected
        .to belong_to(:file_record_parent)
        .class_name('VCS::FileRecord')
        .dependent(false)
        .optional
    end
    it do
      is_expected
        .to belong_to(:current_snapshot)
        .class_name('VCS::FileSnapshot')
        .dependent(false)
        .optional
    end
    it do
      is_expected
        .to belong_to(:committed_snapshot)
        .class_name('VCS::FileSnapshot')
        .dependent(false)
        .optional
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:remote_file_id) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:mime_type) }
    it { is_expected.to validate_presence_of(:content_version) }
    it { is_expected.to validate_presence_of(:file_record_parent_id) }
    it do
      is_expected
        .to validate_uniqueness_of(:remote_file_id).scoped_to(:branch_id)
    end

    it 'validates that file is not its own parent' do
      expect(staged_file).to receive(:cannot_be_its_own_parent)
      staged_file.valid?
    end

    context 'when external id has not changed' do
      before do
        allow(staged_file).to receive(:remote_file_id_changed?).and_return false
      end

      it { expect(staged_file).not_to validate_uniqueness_of(:remote_file_id) }
    end

    context 'when file_record_parent_id has changed' do
      before  { staged_file.file_record_parent_id = 5 }
      after   { staged_file.valid? }

      it { expect(staged_file).to receive(:cannot_be_its_own_ancestor) }
    end

    context 'when file is root' do
      before { allow(staged_file).to receive(:root?).and_return true }

      it { is_expected.not_to validate_presence_of(:file_record_parent_id) }
    end

    context 'when file is deleted' do
      before { allow(staged_file).to receive(:deleted?).and_return true }

      it { is_expected.not_to validate_presence_of(:name) }
      it { is_expected.not_to validate_presence_of(:mime_type) }
      it { is_expected.not_to validate_presence_of(:content_version) }
      it { is_expected.not_to validate_presence_of(:file_record_parent_id) }
    end
  end

  describe '#diff(with_ancestry: false)' do
    subject(:diff) { staged_file.diff }

    before do
      allow(staged_file).to receive(:current_snapshot_id).and_return 55
      allow(staged_file).to receive(:committed_snapshot_id).and_return 99
    end

    it 'returns a file diff with correct snapshots' do
      is_expected.to be_a VCS::FileDiff
      is_expected.to have_attributes(
        new_snapshot_id: 55,
        old_snapshot_id: 99,
        first_three_ancestors: nil
      )
    end

    context 'when @diff is cached' do
      before { staged_file.instance_variable_set(:@diff, 'cached') }

      it { is_expected.to eq 'cached' }
    end

    context 'when with_ancestry: true' do
      subject(:diff) { staged_file.diff(with_ancestry: true) }

      before do
        anc1 = instance_double VCS::FileSnapshot
        anc2 = instance_double VCS::FileSnapshot
        anc3 = instance_double VCS::FileSnapshot
        ancestors = [anc1, anc2, anc3]
        allow(staged_file).to receive(:ancestors).and_return ancestors
        allow(anc1).to receive(:name).and_return 'anc1'
        allow(anc2).to receive(:name).and_return 'anc2'
        allow(anc3).to receive(:name).and_return 'anc3'
      end

      it 'returns a file diff with first three ancestors' do
        is_expected.to be_a VCS::FileDiff
        is_expected.to have_attributes(
          new_snapshot_id: 55,
          old_snapshot_id: 99,
          first_three_ancestors: %w[anc1 anc2 anc3]
        )
      end
    end
  end

  describe '#deleted?' do
    subject(:deleted) { staged_file.deleted? }

    it { is_expected.to be false }

    context 'when is_deleted = true' do
      before { allow(staged_file).to receive(:is_deleted).and_return true }

      it { is_expected.to be true }
    end
  end

  describe '#ancestors' do
    subject(:ancestors) { staged_file.ancestors }

    it { is_expected.to eq [] }

    context 'when file has many ancestors' do
      let(:root)        { create :vcs_staged_file, :root }
      let(:grandparent) { create :vcs_staged_file, parent: root }
      let(:parent)      { create :vcs_staged_file, parent: grandparent }
      let(:staged_file) { create :vcs_staged_file, parent: parent }

      it 'returns staged snapshots of ancestors' do
        expect(ancestors.map(&:id)).to eq(
          [parent, grandparent].map(&:staged_snapshot).map(&:id)
        )
      end

      it 'does not include staged snapshot of root' do
        expect(root).to be_root
        expect(root.staged_snapshot).to be_present
        expect(ancestors.map(&:id)).not_to include(root.staged_snapshot.id)
      end
    end
  end

  describe '#ancestors_ids' do
    subject(:ancestors_ids) { staged_file.ancestors_ids }
    let(:ancestors)         { [] }

    before do
      allow(staged_file).to receive(:ancestors).and_return ancestors
    end

    it { is_expected.to eq [] }

    context 'when file has many ancestors' do
      let(:ancestors)   { [parent, grandparent] }
      let(:grandparent) { instance_double VCS::FileSnapshot }
      let(:parent)      { instance_double VCS::FileSnapshot }

      before do
        allow(grandparent).to receive(:file_record_id).and_return 'gparent'
        allow(parent).to receive(:file_record_id).and_return 'parent'
      end

      it { is_expected.to eq %w[parent gparent] }
    end
  end

  describe '#folder?' do
    subject(:folder_check) { staged_file.folder? }
    before do
      allow(staged_file).to receive(:mime_type).and_return 'mime-type'
      allow(Providers::GoogleDrive::MimeType)
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
    subject(:subfolders)  { staged_file.subfolders }
    let(:folder1)         { instance_double described_class }
    let(:folder2)         { instance_double described_class }
    let(:file1)           { instance_double described_class }
    let(:file2)           { instance_double described_class }

    before do
      allow(staged_file)
        .to receive(:staged_children)
        .and_return [file1, folder1, file2, folder2]

      allow(folder1).to receive(:folder?).and_return true
      allow(folder2).to receive(:folder?).and_return true
      allow(file1).to receive(:folder?).and_return false
      allow(file2).to receive(:folder?).and_return false
    end

    it { is_expected.to contain_exactly folder1, folder2 }
  end

  describe '#cannot_be_its_own_ancestor' do
    subject(:validation)  { staged_file.send :cannot_be_its_own_ancestor }
    let(:ancestors_ids)   { [] }

    before do
      staged_file.save
      allow(staged_file).to receive(:ancestors_ids).and_return ancestors_ids
      validation
    end

    it { expect(staged_file.errors).to be_none }

    context 'when file is its own ancestor' do
      let(:ancestors_ids) { [staged_file.file_record_id] }
      it { expect(staged_file.errors).to be_one }
    end
  end

  describe '#cannot_be_its_own_parent' do
    subject(:validation)  { staged_file.send :cannot_be_its_own_parent }
    let(:parent)          { nil }
    let(:parent_id)       { nil }

    before { staged_file.file_record_parent_id = parent_id if parent_id }
    before { staged_file.file_record_parent    = parent if parent }
    before { validation }

    it { expect(staged_file.errors).to be_none }

    context 'when file is its own parent by ID' do
      let(:parent_id) { staged_file.file_record_id }
      it { expect(staged_file.errors).to be_one }
    end

    context 'when file is its own parent by instance' do
      let(:staged_file) do
        described_class.new(file_record: VCS::FileRecord.new)
      end
      let(:parent) { staged_file.file_record }

      it { expect(staged_file.errors).to be_one }
    end
  end
end
