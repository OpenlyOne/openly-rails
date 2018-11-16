# frozen_string_literal: true

RSpec.describe Providers::GoogleDrive::ApiConnection, type: :model, vcr: true do
  before  { prepare_google_drive_test }
  after   { tear_down_google_drive_test }

  subject(:api) { described_class.default }

  describe '#share_file' do
    subject(:share_file) do
      api.share_file(google_drive_test_folder_id, recipient_email)
    end
    let(:recipient_email) { ENV['GOOGLE_DRIVE_USER_ACCOUNT'] }

    it 'grants read permission to the recipient' do
      share_file
      folder = api.find_file!(google_drive_test_folder_id)
      expect(folder.permissions.count).to eq 2
      expect(folder.permissions).to be_any do |permission|
        permission.role == 'reader' &&
          permission.email_address == recipient_email
      end
    end

    context 'when file has already been shared with the recipient' do
      before { api.share_file(google_drive_test_folder_id, recipient_email) }

      it { expect { share_file }.not_to raise_error }
    end
  end

  describe '#unshare_file' do
    subject(:unshare_file) do
      api.unshare_file(google_drive_test_folder_id, recipient_email)
    end
    let(:recipient_email) { ENV['GOOGLE_DRIVE_USER_ACCOUNT'] }

    before { api.share_file(google_drive_test_folder_id, recipient_email) }

    it 'removes read permission from the recipient' do
      unshare_file
      folder = api.find_file!(google_drive_test_folder_id)
      expect(folder.permissions.count).to eq 1
      expect(folder.permissions).to be_none do |permission|
        permission.role == 'reader' &&
          permission.email_address == recipient_email
      end
    end

    context 'when file has already been unshared with the recipient' do
      before { api.unshare_file(google_drive_test_folder_id, recipient_email) }

      it { expect { unshare_file }.not_to raise_error }
    end
  end
end
