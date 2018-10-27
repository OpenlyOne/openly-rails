# frozen_string_literal: true

RSpec.shared_examples 'being backupable' do
  describe 'callbacks' do
    describe 'after save' do
      subject { backupable }

      before do
        allow(backupable).to receive(:perform_backup)
        allow(backupable).to receive(:backup_on_save?).and_return backup_on_save
        backupable.save
      end

      context 'when backup_on_save? is true' do
        let(:backup_on_save) { true }

        it { is_expected.to have_received(:perform_backup) }
      end

      context 'when backup_on_save? is false' do
        let(:backup_on_save) { false }

        it { is_expected.not_to have_received(:perform_backup) }
      end
    end
  end

  describe '#backed_up?' do
    subject { backupable }

    let(:snapshot)      { instance_double FileResource::Snapshot }
    let(:backup)        { instance_double FileResource::Backup }
    let(:is_persisted)  { false }

    before do
      allow(backupable).to receive(:current_snapshot).and_return snapshot
      next unless snapshot.present?

      allow(snapshot).to receive(:backup).and_return backup
      next unless backup.present?

      allow(backup).to receive(:persisted?).and_return is_persisted
    end

    it { is_expected.not_to be_backed_up }

    context 'when backup is persisted' do
      let(:is_persisted) { true }

      it { is_expected.to be_backed_up }
    end

    context 'when current_snapshot is nil' do
      let(:snapshot) { nil }

      it { is_expected.not_to be_backed_up }
    end

    context 'when backup of current_snapshot is present' do
      let(:backup) { nil }

      it { is_expected.not_to be_backed_up }
    end
  end

  describe '#backup_on_save?' do
    subject { backupable }

    let(:is_folder)     { false }
    let(:is_deleted)    { false }
    let(:is_backed_up)  { false }

    before do
      allow(backupable).to receive(:folder?).and_return is_folder
      allow(backupable).to receive(:deleted?).and_return is_deleted
      allow(backupable).to receive(:backed_up?).and_return is_backed_up
    end

    it { is_expected.to be_backup_on_save }

    context 'when folder' do
      let(:is_folder) { true }

      it { is_expected.not_to be_backup_on_save }
    end

    context 'when deleted' do
      let(:is_deleted) { true }

      it { is_expected.not_to be_backup_on_save }
    end

    context 'when backed up' do
      let(:is_backed_up) { true }

      it { is_expected.not_to be_backup_on_save }
    end
  end

  describe '#perform_backup' do
    subject(:method) { backupable.send(:perform_backup) }

    it 'calls .backup on FileResource::Backup with self' do
      expect(FileResource::Backup).to receive(:backup).with(backupable)
      method
    end

    it 'returns true' do
      allow(FileResource::Backup).to receive(:backup).and_return 'some-output'
      expect(method).to be true
    end
  end
end
