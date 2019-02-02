# frozen_string_literal: true

RSpec.describe VCS::Operations::FileBackup, type: :model do
  subject(:operation)   { described_class.new(file_in_branch) }
  let(:file_in_branch)  { class_double VCS::FileInBranch }

  describe '.backup(file_in_branch)' do
    subject(:method) { described_class.backup('file-in-branch') }

    let(:new_operation) { instance_double described_class }

    before do
      allow(described_class)
        .to receive(:new).with('file-in-branch').and_return new_operation
      allow(new_operation).to receive(:perform_backup)
    end

    it 'calls perform_backup on new operation' do
      method
      expect(new_operation).to have_received(:perform_backup)
    end

    it 'returns the new operation' do
      is_expected.to eq new_operation
    end
  end

  describe '#perform_backup' do
    subject(:perform_backup) { operation.perform_backup }

    let(:is_backed_up)    { false }
    let(:archive)         { instance_double VCS::Archive }
    let(:file_version)    { instance_double VCS::Version }
    let(:file_sync_class) { Providers::GoogleDrive::FileSync }
    let(:remote_backup)   { instance_double file_sync_class }

    before do
      allow(operation).to receive(:backed_up?).and_return is_backed_up
      allow(operation).to receive(:archive).and_return archive
      allow(operation).to receive(:file_version).and_return file_version
      allow(operation).to receive(:remote_backup).and_return remote_backup
      allow(operation).to receive(:create_remote_backup)
      allow(operation).to receive(:store_backup_record)
    end

    it 'creates the remote backup' do
      perform_backup
      expect(operation).to have_received(:create_remote_backup)
    end

    it 'stores a local backup record' do
      perform_backup
      expect(operation).to have_received(:store_backup_record)
    end

    context 'when backup for file already exists' do
      let(:is_backed_up) { true }

      it { is_expected.to be false }

      it 'does not create or store backup' do
        perform_backup
        expect(operation).not_to have_received(:create_remote_backup)
        expect(operation).not_to have_received(:store_backup_record)
      end
    end

    context 'when archive does not exist' do
      let(:archive) { nil }

      it { is_expected.to be false }

      it 'does not create or store backup' do
        perform_backup
        expect(operation).not_to have_received(:create_remote_backup)
        expect(operation).not_to have_received(:store_backup_record)
      end
    end

    context 'when file version does not exist' do
      let(:file_version) { nil }

      it { is_expected.to be false }

      it 'does not create or store backup' do
        perform_backup
        expect(operation).not_to have_received(:create_remote_backup)
        expect(operation).not_to have_received(:store_backup_record)
      end
    end

    context 'when backing up fails' do
      let(:remote_backup) { nil }

      it { is_expected.to be false }

      it 'does not store backup' do
        perform_backup
        expect(operation).to have_received(:create_remote_backup)
        expect(operation).not_to have_received(:store_backup_record)
      end
    end
  end
end
