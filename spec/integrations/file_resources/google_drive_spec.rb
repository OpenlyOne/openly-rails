# frozen_string_literal: true

require 'integrations/shared_examples/including_snapshotable_integration.rb'
require 'integrations/shared_examples/including_stageable_integration.rb'
require 'integrations/shared_examples/including_syncable_integration.rb'

RSpec.describe FileResources::GoogleDrive, type: :model do
  subject(:file) do
    FileResources::GoogleDrive.new(external_id: external_id)
  end
  let(:external_id) { 'id' }

  it_should_behave_like 'including snapshotable integration' do
    let(:file)                    { build :file_resources_google_drive }
    let(:snapshotable)            { file }
    let(:snapshotable_model_name) { 'FileResources::GoogleDrive' }
  end

  it_should_behave_like 'including stageable integration' do
    let(:stageable) { create :file_resource }
    let(:parent)    { create :file_resource }
  end

  it_should_behave_like 'including syncable integration' do
    let(:api)      { Providers::GoogleDrive::ApiConnection.default }
    let(:syncable) { file }
    let(:parent_id) { google_drive_test_folder_id }
    let(:mime_type) { Providers::GoogleDrive::MimeType.document }
    let(:folder_mime_type)  { Providers::GoogleDrive::MimeType.folder }
    let(:file_sync_class)   { Providers::GoogleDrive::FileSync }

    before { prepare_google_drive_test }
    after  { tear_down_google_drive_test }
  end

  describe 'snapshotable + stageable + syncable', :vcr do
    before { prepare_google_drive_test }
    after  { tear_down_google_drive_test }
    let!(:file_sync) do
      Providers::GoogleDrive::FileSync.create(
        name: 'Test File',
        parent_id: google_drive_test_folder_id,
        mime_type: Providers::GoogleDrive::MimeType.document
      )
    end
    let!(:parent) do
      described_class.new(external_id: google_drive_test_folder_id)
    end
    let(:projects)            { create_list :project, 3 }
    let(:api)                 { Providers::GoogleDrive::ApiConnection.default }
    let(:external_id)         { file_sync.id }
    let(:file_from_database)  { FileResource.find_by_external_id!(external_id) }
    let(:file_attributes)     { file_from_database.attributes }
    let(:snapshot_attributes) { file_from_database.current_snapshot.attributes }
    let(:staging_projects)    { file_from_database.staging_projects }
    let(:expected_attributes) do
      {
        'name' => 'Test File',
        'parent_id' => parent.id,
        'content_version' => '1',
        'mime_type' => Providers::GoogleDrive::MimeType.document,
        'external_id' => external_id
      }
    end

    # Pull parent resource & set staged projects
    before do
      parent.pull
      parent.staging_projects = projects
    end

    it 'can pull a snapshot of a new file' do
      file.pull
      expect(file_attributes).to include(expected_attributes)
      expect(snapshot_attributes).to include(expected_attributes)
      expect(staging_projects).to eq projects
    end

    it 'can pull a snapshot of an existing file' do
      file.pull
      file_sync.rename('my new file name')
      file.reload.pull
      expected_attributes['name'] = 'my new file name'
      expect(file_attributes).to include(expected_attributes)
      expect(snapshot_attributes).to include(expected_attributes)
      expect(staging_projects).to eq projects
    end

    it 'can pull a snapshot of a removed file' do
      file.pull
      api.delete_file(file.external_id)
      file.reload.pull
      expect(file_from_database).to be_deleted
      expect(file_from_database.current_snapshot).to be nil
      expect(staging_projects).to eq []
    end
  end
end
