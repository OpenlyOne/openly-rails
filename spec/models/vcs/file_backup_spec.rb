# frozen_string_literal: true

RSpec.describe VCS::FileBackup, type: :model do
  subject(:backup) { build_stubbed :vcs_file_backup }

  describe 'associations' do
    it { is_expected.to belong_to(:file_snapshot).dependent(false) }
  end

  describe 'validations' do
    subject(:backup) { build :vcs_file_backup }

    it do
      is_expected
        .to validate_presence_of(:file_snapshot_id).with_message('must exist')
    end
    it { is_expected.to validate_presence_of(:remote_file_id) }

    context 'when archive is nil' do
      before { allow(backup).to receive(:archive).and_return nil }

      it { is_expected.to be_invalid(:capture) }
      it { is_expected.to be_valid(:create) }
      it { is_expected.to be_valid(:update) }
    end
  end

  describe '.backup(file_in_branch)' do
    subject(:method) { described_class.backup(file_in_branch) }

    let(:file_in_branch)  { instance_double VCS::FileInBranch }
    let(:new_backup)      { instance_double described_class }
    let(:p1)              { instance_double Project }
    let(:p2)              { instance_double Project }

    before do
      allow(file_in_branch).to receive(:current_snapshot).and_return 'snapshot'
      allow(described_class)
        .to receive(:new)
        .with(file_snapshot: 'snapshot')
        .and_return new_backup
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
    subject(:capture_backup) { backup.capture }

    let(:backup) { build(:vcs_file_backup, file_snapshot: snapshot) }
    let(:archive)         { instance_double VCS::Archive }
    let(:snapshot)        { create(:vcs_file_snapshot, name: 'snapshot-name') }
    let(:file_sync_class) { Providers::GoogleDrive::FileSync }
    let(:remote_file)     { instance_double file_sync_class }
    let(:duplicated_remote_file) { file_sync_class.new('dup-remote-id') }

    before do
      allow(backup).to receive(:archive).and_return archive
      allow(backup).to receive(:file_in_branch_remote).and_return remote_file
      allow(backup).to receive(:archive_folder_id).and_return 'archive-id'
      allow(remote_file)
        .to receive(:duplicate).and_return duplicated_remote_file
      allow(backup).to receive(:remote_file_id=)
    end

    it 'duplicates the remote file' do
      capture_backup
      expect(remote_file)
        .to have_received(:duplicate)
        .with(name: 'snapshot-name', parent_id: 'archive-id')
    end

    it 'sets remote id' do
      capture_backup
      expect(backup).to have_received(:remote_file_id=).with('dup-remote-id')
    end

    context 'when backup for file snapshot already exists' do
      before { create(:vcs_file_backup, file_snapshot: snapshot) }

      it { is_expected.to be false }
      it 'does not duplicate remote file' do
        capture_backup
        expect(remote_file).not_to have_received(:duplicate)
      end
    end

    context 'when file resource snapshot is nil' do
      let(:snapshot) { nil }

      it { is_expected.to be false }
      it 'does not duplicate remote file' do
        capture_backup
        expect(remote_file).not_to have_received(:duplicate)
      end
    end

    context 'when archive is nil' do
      let(:archive) { nil }

      it { is_expected.to be false }
      it 'does not duplicate remote file' do
        capture_backup
        expect(remote_file).not_to have_received(:duplicate)
      end
    end

    context 'when duplication fails' do
      let(:duplicated_remote_file) { nil }

      it { is_expected.to be false }
      it 'does not set remote_file_id' do
        capture_backup
        expect(backup).not_to have_received(:remote_file_id=)
      end
    end
  end
end
