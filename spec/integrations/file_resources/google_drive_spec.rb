# frozen_string_literal: true

require 'integrations/shared_examples/including_syncable_integration.rb'

RSpec.describe FileResources::GoogleDrive, type: :model do
  subject(:file) do
    FileResources::GoogleDrive.new(external_id: external_id)
  end
  let(:external_id) { 'id' }

  it_should_behave_like 'including syncable integration' do
    let(:api)      { Providers::GoogleDrive::ApiConnection.default }
    let(:syncable) { file }
    let(:parent_id) { google_drive_test_folder_id }
    let(:mime_type) { Providers::GoogleDrive::MimeType.document }
    let(:file_sync_class) { Providers::GoogleDrive::FileSync }

    before { prepare_google_drive_test }
    after  { tear_down_google_drive_test }
  end
end
