# frozen_string_literal: true

RSpec.describe Project::Archive, type: :model do
  subject(:archive)     { Project::Archive.new(project: project) }
  let(:project)         { build(:project, title: 'Demo', owner: owner) }
  let(:owner)           { build(:user, account: account) }
  let(:account)         { build(:account, email: account_email) }
  let(:account_email)   { ENV['GOOGLE_DRIVE_USER_ACCOUNT'] }
  let(:external_folder) { archive.file_resource }

  describe '#setup', :vcr do
    before  { prepare_google_drive_test }
    after   { tear_down_google_drive_test }

    let(:remote_folder_id) { external_folder.external_id }

    before { archive.setup }
    after do
      # cleanup
      Providers::GoogleDrive::ApiConnection
        .default.delete_file(remote_folder_id)
    end

    it 'creates a folder in Google Drive' do
      folder = FileResources::GoogleDrive.new(external_id: remote_folder_id)
      folder.fetch
      expect(folder).to have_attributes(
        name: "#{project.title} (Archive)",
        mime_type: Providers::GoogleDrive::MimeType.folder,
        parent_id: nil
      )
    end

    it 'shares view access to the archive with the repository owner' do
      folder = Providers::GoogleDrive::FileSync.new(remote_folder_id)
      expect(folder.permissions.count).to eq 2
      expect(folder.permissions).to be_any do |permission|
        permission.role == 'reader' &&
          permission.email_address == account_email
      end
    end
  end
end
