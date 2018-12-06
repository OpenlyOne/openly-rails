# frozen_string_literal: true

RSpec.describe VCS::FileBackup, type: :model do
  let(:project)         { build(:project, title: 'Demo', owner: owner) }
  let(:owner)           { build(:user, account: account) }
  let(:account)         { build(:account, email: account_email) }
  let(:account_email)   { ENV['GOOGLE_DRIVE_USER_ACCOUNT'] }
  let(:remote_folder) { archive.file_resource }

  describe '#capture', :vcr do
    before  { prepare_google_drive_test }
    after   { tear_down_google_drive_test }

    subject(:backup) do
      described_class.new(file_version: version)
    end

    let(:user_acct) { ENV['GOOGLE_DRIVE_USER_ACCOUNT'] }
    let(:version)   { file_in_branch.current_version }
    let(:file_name) { 'An Awesome File' }
    let(:file_in_branch) do
      project.master_branch.files.build(
        remote_file_id: remote_file.id,
        file: VCS::File.new(repository: project.repository)
      )
    end
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
      backup.capture
    end

    after do
      # cleanup
      Providers::GoogleDrive::ApiConnection
        .default.delete_file(archive_folder_id)
    end

    it 'stores a copy of the file version in archive' do
      copy = Providers::GoogleDrive::FileSync.new(backup.remote_file_id)
      expect(copy).to have_attributes(
        name: file_name,
        parent_id: archive.remote_file_id
      )
    end

    it 'inherits access permissions from archive folder' do
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
  end
end
