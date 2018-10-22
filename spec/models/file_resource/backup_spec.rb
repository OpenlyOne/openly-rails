# frozen_string_literal: true

RSpec.describe FileResource::Backup, type: :model do
  subject(:backup) { build_stubbed :file_resource_backup }

  describe 'associations' do
    it do
      is_expected
        .to belong_to(:file_resource_snapshot)
        .class_name('FileResource::Snapshot')
        .validate(false)
        .dependent(false)
    end
    it do
      is_expected
        .to belong_to(:archive)
        .class_name('Project::Archive')
        .validate(false)
        .dependent(false)
    end
    it do
      is_expected.to belong_to(:file_resource).validate(false).dependent(false)
    end
  end

  describe 'validations' do
    subject(:backup) { build :file_resource_backup }

    it do
      is_expected
        .to validate_presence_of(:file_resource_snapshot)
        .with_message('must exist')
    end
    it do
      is_expected
        .to validate_presence_of(:archive).with_message('must exist')
    end

    it do
      is_expected
        .to validate_uniqueness_of(:file_resource_snapshot_id)
        .with_message('already has a backup')
        .case_insensitive
    end
  end

  describe '.backup(file_resource_to_backup)' do
    subject(:method) { described_class.backup(file_resource) }

    let(:file_resource) { instance_double FileResource }
    let(:new_backup)    { instance_double described_class }
    let(:p1)            { instance_double Project }
    let(:p2)            { instance_double Project }

    before do
      allow(file_resource).to receive(:current_snapshot).and_return 'snapshot'
      allow(file_resource).to receive(:staging_projects).and_return [p1, p2]
      allow(p1).to receive(:archive).and_return 'archive'
      allow(described_class).to receive(:new).with(
        file_resource_snapshot: 'snapshot',
        archive: 'archive'
      ).and_return new_backup
      allow(new_backup).to receive(:capture)
      allow(new_backup).to receive(:save)
    end

    it 'calls capture on new backup' do
      method
      expect(new_backup).to have_received(:capture)
    end

    it 'calls save on new backup' do
      method
      expect(new_backup).to have_received(:save)
    end

    it 'returns the new backup' do
      is_expected.to eq new_backup
    end
  end

  describe '#capture' do
    subject(:method) { backup.capture }

    let(:backup) do
      build(:file_resource_backup,
            file_resource_snapshot: snapshot,
            archive: archive)
    end
    let(:snapshot)  { create(:file_resource_snapshot, name: 'snapshot-name') }
    let(:archive)   { build(:project_archive, file_resource: remote_archive) }
    let(:remote_archive)  { build(:file_resource, external_id: 'archive-id') }
    let(:file_sync_class) { Providers::GoogleDrive::FileSync }
    let(:remote_file)     { instance_double file_sync_class }
    let(:duplicated_remote_file) { file_sync_class.new('dup-remote-id') }

    before do
      allow(backup).to receive(:file_resource_remote).and_return remote_file
      allow(remote_file)
        .to receive(:duplicate).and_return duplicated_remote_file
      allow(backup).to receive(:create_file_resource!)
    end

    it 'duplicates the remote file' do
      expect(remote_file)
        .to receive(:duplicate)
        .with(name: 'snapshot-name', parent_id: 'archive-id')
      method
    end

    it 'creates file resource for backup' do
      expect(backup).to receive(:create_file_resource!).with('dup-remote-id')
      method
    end

    context 'when backup for file resource snapshot already exists' do
      before { create(:file_resource_backup, file_resource_snapshot: snapshot) }

      it { is_expected.to be false }
      it 'does not duplicate remote file' do
        expect(remote_file).not_to receive(:duplicate)
        method
      end
    end

    context 'when file resource snapshot is nil' do
      let(:snapshot) { nil }

      it { is_expected.to be false }
      it 'does not duplicate remote file' do
        expect(remote_file).not_to receive(:duplicate)
        method
      end
    end

    context 'when archive is nil' do
      let(:archive) { nil }

      it { is_expected.to be false }
      it 'does not duplicate remote file' do
        expect(remote_file).not_to receive(:duplicate)
        method
      end
    end

    context 'when duplication fails' do
      let(:duplicated_remote_file) { nil }

      it { is_expected.to be false }
      it 'does not create file resource' do
        expect(backup).not_to receive(:create_file_resource!)
        method
      end
    end
  end

  describe '#create_file_resource!(external_id)' do
    subject(:method) { backup.send(:create_file_resource!, 'ext-id') }

    let(:snapshot) { instance_double FileResource::Snapshot }

    before do
      allow(backup).to receive(:file_resource_snapshot).and_return snapshot
      allow(snapshot).to receive(:mime_type).and_return 'mime-type-of-snapshot'
    end

    it 'creates a FileResource' do
      method
      expect(FileResource).to exist(
        external_id: 'ext-id',
        name: 'Backup',
        mime_type: 'mime-type-of-snapshot',
        content_version: 0
      )
    end
  end
end
