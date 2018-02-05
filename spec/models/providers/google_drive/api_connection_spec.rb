# frozen_string_literal: true

RSpec.describe Providers::GoogleDrive::ApiConnection, type: :model do
  subject(:api)       { Providers::GoogleDrive::ApiConnection.new(account) }
  let(:drive_service) { double Providers::GoogleDrive::DriveService }
  let(:account)       { 'example@gmail.com' }

  before do
    allow(Providers::GoogleDrive::DriveService)
      .to receive(:new).with(account).and_return drive_service
  end

  describe '.default' do
    subject(:method) { described_class.default }
    before { allow(Providers::GoogleDrive::DriveService).to receive(:new) }
    it { is_expected.to be_an_instance_of described_class }
  end

  describe '.tracking_account' do
    subject(:method) { described_class.tracking_account }
    before { allow(Providers::GoogleDrive::DriveService).to receive(:new) }
    it { is_expected.to be_an_instance_of described_class }
  end

  describe '#create_file(name, parent_id, mime_type)' do
    subject(:create_file) { api.create_file(args) }
    let(:args) { { name: 'name', parent_id: 'parent-id', mime_type: 'doc' } }
    before  { allow(api).to receive(:default_file_fields).and_return 'default' }
    before  { allow(drive_service).to receive(:create_file) }
    after   { create_file }

    it 'calls #create_file on drive service' do
      expect(drive_service)
        .to receive(:create_file)
        .with(instance_of(Google::Apis::DriveV3::File), fields: 'default')
    end

    it 'calls #create_file with name' do
      expect(drive_service)
        .to receive(:create_file) do |*args|
        expect(args[0].name).to eq 'name'
      end
    end

    it 'calls #create_file with parent_id' do
      expect(drive_service)
        .to receive(:create_file) do |*args|
        expect(args[0].parents.first).to eq 'parent-id'
      end
    end

    it 'calls #create_file with mime_type' do
      expect(drive_service)
        .to receive(:create_file) do |*args|
        expect(args[0].mime_type).to eq 'doc'
      end
    end
  end

  describe '#create_file_in_home_folder(name, mime_type)' do
    subject(:create_file) { api.create_file_in_home_folder(args) }
    let(:args) { { name: 'name', mime_type: 'doc' } }
    before  { allow(api).to receive(:default_file_fields).and_return 'default' }
    after   { create_file }

    it { expect(api).to receive(:create_file) }

    it do
      expect(api).to receive(:create_file).with(hash_including(name: 'name'))
    end

    it do
      expect(api)
        .to receive(:create_file).with(hash_including(parent_id: 'root'))
    end

    it do
      expect(api)
        .to receive(:create_file).with(hash_including(mime_type: 'doc'))
    end
  end

  describe '#delete_file(id)' do
    subject(:delete_file) { api.delete_file('file-id') }
    after                 { delete_file }

    it { expect(drive_service).to receive(:delete_file).with('file-id') }
  end

  describe '#fetch_file(id)' do
    subject(:fetch_file) { api.fetch_file('file-id') }
    before  { allow(api).to receive(:default_file_fields).and_return 'default' }
    after   { fetch_file }

    it 'calls #get_file on drive service' do
      expect(drive_service)
        .to receive(:get_file)
        .with('file-id', fields: 'default')
    end
  end

  describe '#file_permission_id_by_email(id, email)' do
    subject(:file_permission_id) do
      api.file_permission_id_by_email('file-id', 'example@gmail.com')
    end
    let(:permissions) { [permission1, permission2, permission3] }
    let(:permission1) { permission.new(id: '1', email_address: 'a@b.com') }
    let(:permission2) do
      permission.new(id: 'permission-id', email_address: 'example@gmail.com')
    end
    let(:permission3) { permission.new(id: '3', email_address: 'a@b.com') }
    let(:permission)  { Google::Apis::DriveV3::Permission }
    after { file_permission_id }

    before do
      permission_list = instance_double Google::Apis::DriveV3::PermissionList
      allow(drive_service)
        .to receive(:list_permissions).and_return permission_list
      allow(permission_list)
        .to receive(:permissions).and_return permissions
    end

    it 'calls #list_permissions on drive service' do
      expect(drive_service)
        .to receive(:list_permissions)
        .with('file-id', fields: 'permissions/id, permissions/emailAddress')
    end

    it { is_expected.to eq 'permission-id' }
  end

  describe '#share_file(id, email, role = :reader)' do
    subject(:share_file) { api.share_file('file-id', 'email@example.com') }
    after { share_file }

    it do
      expect(drive_service)
        .to receive(:create_permission)
        .with('file-id', instance_of(Google::Apis::DriveV3::Permission),
              send_notification_email: 'false')
    end

    it 'calls #create_permission with email' do
      expect(drive_service).to receive(:create_permission) do |*args|
        expect(args[1].email_address).to eq 'email@example.com'
      end
    end

    it 'calls #create_permission with type: user' do
      expect(drive_service).to receive(:create_permission) do |*args|
        expect(args[1].type).to eq 'user'
      end
    end

    it 'calls #create_permission with role: reader' do
      expect(drive_service).to receive(:create_permission) do |*args|
        expect(args[1].role).to eq 'reader'
      end
    end

    context 'when role is passed' do
      subject(:share_file) { api.share_file('id', 'email', 'custom-role') }

      it 'calls #create_permission with custom role' do
        expect(drive_service).to receive(:create_permission) do |*args|
          expect(args[1].role).to eq 'custom-role'
        end
      end
    end
  end

  describe '#trash_file(id)' do
    subject(:trash_file) { api.trash_file('file-id') }
    before  { allow(api).to receive(:default_file_fields).and_return 'default' }
    after   { trash_file }

    it do
      expect(drive_service)
        .to receive(:update_file)
        .with('file-id',
              instance_of(Google::Apis::DriveV3::File),
              fields: 'default')
    end

    it 'calls #update_file with trashed: true' do
      expect(drive_service)
        .to receive(:update_file) do |*args|
        expect(args[1].trashed).to eq 'true'
      end
    end
  end

  describe '#unshare_file(id, email)' do
    subject(:unshare_file) { api.unshare_file('file-id', 'example@gmail.com') }
    after { unshare_file }

    before do
      allow(api)
        .to receive(:file_permission_id_by_email)
        .with('file-id', 'example@gmail.com')
        .and_return 'permission-id'
    end

    it do
      expect(drive_service)
        .to receive(:delete_permission).with('file-id', 'permission-id')
    end
  end

  describe '#update_file_content(id, content)' do
    subject(:update_file_content) do
      api.update_file_content('file-id', 'content')
    end
    after { update_file_content }

    before do
      allow(StringIO).to receive(:new).with('content').and_return 'string-io'
    end

    it do
      expect(drive_service)
        .to receive(:update_file).with('file-id', upload_source: 'string-io')
    end
  end

  describe '#update_file_name(id, name)' do
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
        .to receive(:update_file) do |*args|
        expect(args[1].name).to eq 'new-name'
      end
    end
  end

  describe '#update_file_parents(id, add:, remove:)' do
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

  describe '#default_file_fields' do
    subject(:default_file_fields) { api.send(:default_file_fields) }
    it { is_expected.to match 'id' }
    it { is_expected.to match 'name' }
    it { is_expected.to match 'mimeType' }
    it { is_expected.to match 'parents' }
  end
end
