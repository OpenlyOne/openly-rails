# frozen_string_literal: true

RSpec.describe FileResource::Backup, type: :model do
  before { skip('Model is pending deletion') }

  let(:project)         { build(:project, title: 'Demo', owner: owner) }
  let(:owner)           { build(:user, account: account) }
  let(:account)         { build(:account, email: account_email) }
  let(:account_email)   { ENV['GOOGLE_DRIVE_USER_ACCOUNT'] }
  let(:external_folder) { archive.file_resource }

  describe '#capture', :vcr do
    before  { prepare_google_drive_test }
    after   { tear_down_google_drive_test }

    subject(:backup) do
      FileResource::Backup
        .new(archive: archive, file_resource_snapshot: snapshot)
    end

    let(:user_acct)     { ENV['GOOGLE_DRIVE_USER_ACCOUNT'] }
    let(:snapshot)      { file_resource.current_snapshot }
    let(:file_name)     { 'An Awesome File' }
    let(:file_resource) do
      FileResources::GoogleDrive
        .new(external_id: external_file.id).tap(&:pull)
    end
    let(:external_file) do
      Providers::GoogleDrive::FileSync.create(
        name: file_name,
        parent_id: google_drive_test_folder_id,
        mime_type: Providers::GoogleDrive::MimeType.document
      )
    end
    let(:archive_folder_id) { archive.file_resource.external_id }
    let(:archive)           { project.archive }
    let(:project)           { create(:project, owner_account_email: user_acct) }

    before { backup.capture }

    after do
      # cleanup
      Providers::GoogleDrive::ApiConnection
        .default.delete_file(archive_folder_id)
    end

    it 'stores a copy of the file snapshot in archive' do
      backup.file_resource.fetch
      expect(backup.file_resource).to have_attributes(
        name: file_name,
        parent: FileResource.find_by_external_id(archive_folder_id)
      )
    end

    it 'inherits access permissions from archive folder' do
      archive_permissions_hash =
        Providers::GoogleDrive::FileSync
        .new(archive.file_resource.external_id)
        .permissions
        .map(&:to_h)
      backup_permissions_hash =
        Providers::GoogleDrive::FileSync
        .new(backup.file_resource.external_id)
        .permissions
        .map(&:to_h)
      expect(backup_permissions_hash).to match_array(archive_permissions_hash)
    end
  end
end
