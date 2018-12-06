# frozen_string_literal: true

RSpec.describe VCS::Archive, type: :model do
  subject(:archive) do
    VCS::Archive.new(name: name, owner_account_email: account_email)
  end
  let(:account_email)   { ENV['GOOGLE_DRIVE_USER_ACCOUNT'] }
  let(:name)            { 'DEMO' }
  let(:remote_folder) { archive.file_resource }

  describe '#setup', :vcr do
    before  { prepare_google_drive_test }
    after   { tear_down_google_drive_test }

    let(:remote_folder_id) { archive.remote_file_id }

    before { archive.setup }
    after do
      # cleanup
      Providers::GoogleDrive::ApiConnection
        .default.delete_file(remote_folder_id)
    end

    it 'creates a folder in Google Drive' do
      folder = Providers::GoogleDrive::FileSync.new(remote_folder_id)
      root = Providers::GoogleDrive::FileSync.new('root')
      expect(folder).to have_attributes(
        name: "#{name} (Archive)",
        mime_type: Providers::GoogleDrive::MimeType.folder,
        parent_id: root.send(:file).id
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
