# frozen_string_literal: true

RSpec.describe Providers::GoogleDrive::Api, type: :model do
  subject(:api)       { Providers::GoogleDrive::Api }
  let(:drive_service) { Google::Apis::DriveV3::DriveService.new }

  before do
    allow(api).to receive(:drive_service).and_return drive_service
  end

  describe '.create_file(name, parent_id, mime_type)' do
    subject(:create_file) { api.create_file('name', 'parent-id', 'document') }
    before  { allow(api).to receive(:default_file_fields).and_return 'default' }
    after   { create_file }

    it 'calls #create_file on drive service' do
      expect(drive_service)
        .to receive(:create_file)
        .with(instance_of(Google::Apis::DriveV3::File), fields: 'default')
    end

    it 'calls #create_file with name' do
      expect(drive_service)
        .to receive(:create_file).and_wrap_original do |_object, *args|
        expect(args[0].name).to eq 'name'
      end
    end

    it 'calls #create_file with parent_id' do
      expect(drive_service)
        .to receive(:create_file).and_wrap_original do |_object, *args|
        expect(args[0].parents.first).to eq 'parent-id'
      end
    end

    it 'calls #create_file with mime_type' do
      expect(drive_service)
        .to receive(:create_file).and_wrap_original do |_object, *args|
        expect(args[0].mime_type).to eq 'document'
      end
    end
  end

  describe '.create_file_in_home_folder(name, mime_type)' do
    subject(:create_file) { api.create_file_in_home_folder('name', 'document') }
    before  { allow(api).to receive(:default_file_fields).and_return 'default' }
    after   { create_file }

    it 'calls #create_file on drive service' do
      expect(drive_service)
        .to receive(:create_file)
        .with(instance_of(Google::Apis::DriveV3::File), fields: 'default')
    end

    it 'calls #create_file with name' do
      expect(drive_service)
        .to receive(:create_file).and_wrap_original do |_object, *args|
        expect(args[0].name).to eq 'name'
      end
    end

    it 'calls #create_file without parent_id' do
      expect(drive_service)
        .to receive(:create_file).and_wrap_original do |_object, *args|
        expect(args[0].parents).not_to be_present
      end
    end

    it 'calls #create_file with mime_type' do
      expect(drive_service)
        .to receive(:create_file).and_wrap_original do |_object, *args|
        expect(args[0].mime_type).to eq 'document'
      end
    end
  end

  describe '.delete_file(id)' do
    subject(:delete_file) { api.delete_file('file-id') }
    after                 { delete_file }

    it { expect(drive_service).to receive(:delete_file).with('file-id') }
  end

  describe '.fetch_file(id)' do
    subject(:fetch_file) { api.fetch_file('file-id') }
    before  { allow(api).to receive(:default_file_fields).and_return 'default' }
    after   { fetch_file }

    it 'calls #get_file on drive service' do
      expect(drive_service)
        .to receive(:get_file)
        .with('file-id', fields: 'default')
    end
  end

  describe '.setup' do
    subject(:method) { api.setup }

    it 'initializes the drive service instance' do
      expect(api).to receive(:initialize_drive_service)
      method
    end
  end

  describe '.update_file_name(id, name)' do
    subject(:update_file_name) { api.update_file_name('file-id', 'new-name') }
    before  { allow(api).to receive(:default_file_fields).and_return 'default' }
    after   { update_file_name }

    it do
      expect(drive_service)
        .to receive(:update_file)
        .with('file-id',
              instance_of(Google::Apis::DriveV3::File),
              fields: 'default')
    end

    it 'calls #update_file with name' do
      expect(drive_service)
        .to receive(:update_file).and_wrap_original do |_object, *args|
        expect(args[1].name).to eq 'new-name'
      end
    end
  end

  describe '.update_file_parents(id, add:, remove:)' do
    subject(:update_file_parents) do
      api.update_file_parents('file-id', add: add, remove: remove)
    end
    let(:add)     { ['add-parent'] }
    let(:remove)  { ['remove-parent'] }
    before  { allow(api).to receive(:default_file_fields).and_return 'default' }
    after   { update_file_parents }

    it do
      expect(drive_service)
        .to receive(:update_file)
        .with('file-id', nil,
              add_parents: add, remove_parents: remove,
              fields: 'default')
    end
  end

  describe '.default_file_fields' do
    subject(:default_file_fields) { api.send(:default_file_fields) }
    it { is_expected.to match 'id' }
    it { is_expected.to match 'name' }
    it { is_expected.to match 'mimeType' }
    it { is_expected.to match 'parents' }
  end
end
