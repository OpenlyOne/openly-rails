# frozen_string_literal: true

RSpec.describe VCS::Operations::FileBackup, type: :model, vcr: true do
  # let(:project)         { build(:project, title: 'Demo', owner: owner) }
  # let(:owner)           { build(:user, account: account) }
  # let(:account)         { build(:account, email: account_email) }
  # let(:account_email)   { ENV['GOOGLE_DRIVE_USER_ACCOUNT'] }
  # let(:remote_folder) { archive.file_resource }

  subject(:operation)   { described_class.new(file_in_branch) }

  let(:file_in_branch)  { build :vcs_file_in_branch, current_version: version }
  let(:version)         { create :vcs_version }

  describe '.backup', :vcr do
    before  { prepare_google_drive_test }
    after   { tear_down_google_drive_test }

    subject(:perform_backup) do
      described_class.backup(file_in_branch)
    end

    let(:backup)    { VCS::FileBackup.find_by!(file_version: file_version) }
    let(:user_acct) { ENV['GOOGLE_DRIVE_USER_ACCOUNT'] }
    let(:file_name) { 'An Awesome File' }
    let(:file_in_branch) do
      project.master_branch.files.build(
        remote_file_id: remote_file.id,
        file: VCS::File.new(repository: project.repository)
      )
    end
    let(:file_version) { file_in_branch.current_version }
    let(:remote_file) do
      Providers::GoogleDrive::FileSync.create(
        name: file_name,
        parent_id: google_drive_test_folder_id,
        mime_type: Providers::GoogleDrive::MimeType.document
      )
    end
    let(:archive_folder_id) { archive.remote_file_id }
    let(:archive)           { project.archive }
    let(:project)           { create(:project, owner_account_email: user_acct) }

    before do
      create :vcs_file_in_branch, :root,
             branch: project.master_branch,
             remote_file_id: google_drive_test_folder_id

      # Prevent automatic backup
      allow(file_in_branch).to receive(:backup_on_save?).and_return(false)
      file_in_branch.pull
    end

    after do
      # cleanup
      Providers::GoogleDrive::ApiConnection
        .default.delete_file(archive_folder_id)
    end

    it 'stores a copy of the file version in archive' do
      perform_backup
      copy = Providers::GoogleDrive::FileSync.new(backup.remote_file_id)
      expect(copy).to have_attributes(
        name: file_name,
        parent_id: archive.remote_file_id
      )
    end

    it 'creates a local record of the backup' do
      perform_backup
      expect(VCS::FileBackup).to exist(file_version: file_in_branch.version)
    end

    it 'inherits access permissions from archive folder' do
      perform_backup
      archive_permissions_hash =
        Providers::GoogleDrive::FileSync
        .new(archive.remote_file_id)
        .permissions
        .map(&:to_h)
      backup_permissions_hash =
        Providers::GoogleDrive::FileSync
        .new(backup.remote_file_id)
        .permissions
        .map(&:to_h)
      expect(backup_permissions_hash).to match_array(archive_permissions_hash)
    end

    context 'when version has already been backed up' do
      before { described_class.backup(file_in_branch) }

      it 'calling .backup does not trigger an error' do
        expect { perform_backup }.not_to raise_error
      end
    end

    context 'when file in branch cannot be backed up (eg folder)' do
      let(:remote_file) do
        Providers::GoogleDrive::FileSync.create(
          name: file_name,
          parent_id: google_drive_test_folder_id,
          mime_type: Providers::GoogleDrive::MimeType.folder
        )
      end

      it 'calling .backup does not trigger an error' do
        expect { perform_backup }.not_to raise_error
        expect(VCS::FileBackup).to be_none
      end
    end
  end

  describe '#backed_up?' do
    subject(:method) { operation.backed_up? }

    it { is_expected.to be false }

    context 'when VCS::FileBackup for this version already exists' do
      before do
        VCS::FileBackup.create!(file_version: version, remote_file_id: 'abc')
      end

      it { is_expected.to be true }
    end
  end
end
