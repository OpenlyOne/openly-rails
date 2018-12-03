# frozen_string_literal: true

require 'models/shared_examples/vcs/being_backupable.rb'
require 'models/shared_examples/vcs/being_resourceable.rb'
require 'models/shared_examples/vcs/being_snapshotable.rb'
require 'models/shared_examples/vcs/being_syncable.rb'

RSpec.describe VCS::FileInBranch, type: :model do
  subject(:file_in_branch) { build :vcs_file_in_branch }

  it_should_behave_like 'vcs: being backupable' do
    let(:backupable) { file_in_branch }
  end

  it_should_behave_like 'vcs: being resourceable' do
    let(:resourceable)    { file_in_branch }
    let(:icon_class)      { Providers::GoogleDrive::Icon }
    let(:link_class)      { Providers::GoogleDrive::Link }
    let(:mime_type_class) { Providers::GoogleDrive::MimeType }
  end

  it_should_behave_like 'vcs: being snapshotable' do
    let(:snapshotable) { file_in_branch }
    before do
      allow(file_in_branch).to receive(:backup_on_save?).and_return false
    end
  end

  it_should_behave_like 'vcs: being syncable' do
    let(:syncable) { file_in_branch }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:branch).dependent(false) }
    it { is_expected.to belong_to(:file).dependent(false) }
    it do
      is_expected
        .to belong_to(:parent)
        .class_name('VCS::File')
        .dependent(false)
        .optional
    end
    it do
      is_expected
        .to belong_to(:parent)
        .class_name('VCS::File')
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
    it { is_expected.to validate_presence_of(:parent_id) }
    it do
      is_expected
        .to validate_uniqueness_of(:remote_file_id).scoped_to(:branch_id)
    end

    it 'validates that file is not its own parent' do
      expect(file_in_branch).to receive(:cannot_be_its_own_parent)
      file_in_branch.valid?
    end

    context 'when remote id has not changed' do
      before do
        allow(file_in_branch)
          .to receive(:remote_file_id_changed?)
          .and_return false
      end

      it do
        expect(file_in_branch).not_to validate_uniqueness_of(:remote_file_id)
      end
    end

    context 'when parent_id has changed' do
      before  { file_in_branch.parent_id = 5 }
      after   { file_in_branch.valid? }

      it { expect(file_in_branch).to receive(:cannot_be_its_own_ancestor) }
    end

    context 'when file is root' do
      before { allow(file_in_branch).to receive(:root?).and_return true }

      it { is_expected.not_to validate_presence_of(:parent_id) }
    end

    context 'when file is deleted' do
      before { allow(file_in_branch).to receive(:deleted?).and_return true }

      it { is_expected.not_to validate_presence_of(:name) }
      it { is_expected.not_to validate_presence_of(:mime_type) }
      it { is_expected.not_to validate_presence_of(:content_version) }
      it { is_expected.not_to validate_presence_of(:parent_id) }
    end
  end

  describe '#diff(with_ancestry: false)' do
    subject(:diff) { file_in_branch.diff }

    before do
      allow(file_in_branch).to receive(:current_snapshot_id).and_return 55
      allow(file_in_branch).to receive(:committed_snapshot_id).and_return 99
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
      before { file_in_branch.instance_variable_set(:@diff, 'cached') }

      it { is_expected.to eq 'cached' }
    end

    context 'when with_ancestry: true' do
      subject(:diff) { file_in_branch.diff(with_ancestry: true) }

      before do
        anc1 = instance_double VCS::FileSnapshot
        anc2 = instance_double VCS::FileSnapshot
        anc3 = instance_double VCS::FileSnapshot
        ancestors = [anc1, anc2, anc3]
        allow(file_in_branch).to receive(:ancestors).and_return ancestors
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
    subject(:deleted) { file_in_branch.deleted? }

    it { is_expected.to be false }

    context 'when is_deleted = true' do
      before { allow(file_in_branch).to receive(:is_deleted).and_return true }

      it { is_expected.to be true }
    end
  end

  describe '#ancestors' do
    subject(:ancestors) { file_in_branch.ancestors }

    it { is_expected.to eq [] }

    context 'when file has many ancestors' do
      let(:root)        { create :vcs_file_in_branch, :root }
      let(:grandparent) do
        create :vcs_file_in_branch, parent_in_branch: root
      end
      let(:parent) do
        create :vcs_file_in_branch, parent_in_branch: grandparent
      end
      let(:file_in_branch) do
        create :vcs_file_in_branch, parent_in_branch: parent
      end

      it 'returns snapshots of ancestors' do
        expect(ancestors.map(&:id)).to eq(
          [parent, grandparent].map(&:snapshot).map(&:id)
        )
      end

      it 'does not include snapshot of root' do
        expect(root).to be_root
        expect(root.snapshot).to be_present
        expect(ancestors.map(&:id)).not_to include(root.snapshot.id)
      end
    end
  end

  describe '#ancestors_ids' do
    subject(:ancestors_ids) { file_in_branch.ancestors_ids }
    let(:ancestors)         { [] }

    before do
      allow(file_in_branch).to receive(:ancestors).and_return ancestors
    end

    it { is_expected.to eq [] }

    context 'when file has many ancestors' do
      let(:ancestors)   { [parent, grandparent] }
      let(:grandparent) { instance_double VCS::FileSnapshot }
      let(:parent)      { instance_double VCS::FileSnapshot }

      before do
        allow(grandparent).to receive(:file_id).and_return 'gparent'
        allow(parent).to receive(:file_id).and_return 'parent'
      end

      it { is_expected.to eq %w[parent gparent] }
    end
  end

  describe '#folder?' do
    subject(:folder_check) { file_in_branch.folder? }
    before do
      allow(file_in_branch).to receive(:mime_type).and_return 'mime-type'
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
    subject(:subfolders)  { file_in_branch.subfolders }
    let(:folder1)         { instance_double described_class }
    let(:folder2)         { instance_double described_class }
    let(:file1)           { instance_double described_class }
    let(:file2)           { instance_double described_class }

    before do
      allow(file_in_branch)
        .to receive(:children_in_branch)
        .and_return [file1, folder1, file2, folder2]

      allow(folder1).to receive(:folder?).and_return true
      allow(folder2).to receive(:folder?).and_return true
      allow(file1).to receive(:folder?).and_return false
      allow(file2).to receive(:folder?).and_return false
    end

    it { is_expected.to contain_exactly folder1, folder2 }
  end

  describe '#cannot_be_its_own_ancestor' do
    subject(:validation)  { file_in_branch.send :cannot_be_its_own_ancestor }
    let(:ancestors_ids)   { [] }

    before do
      file_in_branch.save
      allow(file_in_branch).to receive(:ancestors_ids).and_return ancestors_ids
      validation
    end

    it { expect(file_in_branch.errors).to be_none }

    context 'when file is its own ancestor' do
      let(:ancestors_ids) { [file_in_branch.file_id] }
      it { expect(file_in_branch.errors).to be_one }
    end
  end

  describe '#cannot_be_its_own_parent' do
    subject(:validation)  { file_in_branch.send :cannot_be_its_own_parent }
    let(:parent)          { nil }
    let(:parent_id)       { nil }

    before { file_in_branch.parent_id = parent_id if parent_id }
    before { file_in_branch.parent    = parent if parent }
    before { validation }

    it { expect(file_in_branch.errors).to be_none }

    context 'when file is its own parent by ID' do
      let(:parent_id) { file_in_branch.file_id }
      it { expect(file_in_branch.errors).to be_one }
    end

    context 'when file is its own parent by instance' do
      let(:file_in_branch) do
        described_class.new(file: VCS::File.new)
      end
      let(:parent) { file_in_branch.file }

      it { expect(file_in_branch.errors).to be_one }
    end
  end
end
