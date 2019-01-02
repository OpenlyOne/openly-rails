# frozen_string_literal: true

RSpec.describe Providers::GoogleDrive::ApiConnection, type: :model do
  subject(:api)       { Providers::GoogleDrive::ApiConnection.new(account) }
  let(:drive_service) { double Providers::GoogleDrive::DriveService }
  let(:account)       { 'example@gmail.com' }

  before do
    allow(Providers::GoogleDrive::DriveService)
      .to receive(:new).with(account).and_return drive_service
  end

  # Reset class instance variables
  # This is necessary because the mocked call to .tracking_account sets
  # the @tracking_account class instance variable to an incorrect value.
  # In order for ApiConnection to work as expected for subsequent tests,
  # the value must be reset.
  after do
    described_class.instance_variables.each do |ivar|
      described_class.instance_variable_set(ivar, nil)
    end
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
        .with(kind_of(Google::Apis::DriveV3::File), fields: 'default')
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

  describe '#download_file(id)' do
    subject(:download_file) { api.download_file('id') }
    after                   { download_file }

    it do
      expect(api).to receive(:tempfile).and_yield('dest')
      expect(drive_service)
        .to receive(:get_file).with('id', download_dest: 'dest')
    end
  end

  describe '#duplicate_file(id, name:, parent_id:)' do
    subject(:duplicate_file) do
      api.duplicate_file('file-id', name: 'duplicate', parent_id: 'parent-id')
    end
    before do
      allow(api).to receive(:duplicate_file!).with(
        'file-id',
        name: 'duplicate',
        parent_id: 'parent-id'
      ).and_return 'duplicated-file'
    end

    it { is_expected.to eq 'duplicated-file' }

    context 'when an error is raised' do
      before { allow(api).to receive(:duplicate_file!).and_raise error }

      context 'Google::Apis::ClientError, cannotCopyFile' do
        let(:error) { Google::Apis::ClientError.new('cannotCopyFile') }

        it { is_expected.to eq nil }
      end

      context 'Google::Apis::ClientError of different type' do
        let(:error) { Google::Apis::ClientError.new('invalid') }

        it do
          expect { duplicate_file }.to raise_error Google::Apis::ClientError
        end
      end

      context 'when it raises a different error' do
        let(:error) { StandardError.new }

        it { expect { duplicate_file }.to raise_error StandardError }
      end
    end
  end

  describe '#duplicate_file!(id, name:, parent_id:)' do
    subject(:duplicate_file) do
      api.duplicate_file!('file-id', name: 'duplicate', parent_id: 'parent-id')
    end

    before  { allow(api).to receive(:default_file_fields).and_return 'default' }
    after   { duplicate_file }

    it do
      expect(drive_service)
        .to receive(:copy_file)
        .with('file-id',
              kind_of(Google::Apis::DriveV3::File),
              fields: 'default')
    end

    it 'calls #copy_file with name' do
      expect(drive_service)
        .to receive(:copy_file) do |*args|
        expect(args[1].name).to eq 'duplicate'
        expect(args[1].parents).to match_array('parent-id')
      end
    end
  end

  describe '#export_file(id, format:)' do
    subject(:export_file) { api.export_file('id', format: 'format') }
    after { export_file }

    it do
      expect(api).to receive(:tempfile).and_yield('dest')
      expect(drive_service)
        .to receive(:export_file).with('id', 'format', download_dest: 'dest')
    end
  end

  describe 'file_content(id)' do
    subject(:file_content) { api.file_content('id') }

    let(:content) { 'content' }

    before do
      allow(drive_service)
        .to receive(:export_file) do |_id, _format, download_dest:|
        download_dest << content
      end
    end

    it { is_expected.to eq 'content' }

    context 'when content starts with BOM' do
      let(:content) { "\xEF\xBB\xBFcontent" }

      it 'removes BOM' do
        is_expected.to eq 'content'
      end
    end
  end

  describe '#find_file(id)' do
    subject(:find_file) { api.find_file('id') }
    before { allow(api).to receive(:find_file!).with('id').and_return 'file' }

    it { is_expected.to eq 'file' }

    context 'when an error is raised' do
      before { allow(api).to receive(:find_file!).and_raise error }

      context 'Google::Apis::ClientError, notFound' do
        let(:error) { Google::Apis::ClientError.new('notFound') }

        it { is_expected.to eq nil }
      end

      context 'Google::Apis::ClientError of different type' do
        let(:error) { Google::Apis::ClientError.new('invalid') }

        it { expect { find_file }.to raise_error Google::Apis::ClientError }
      end

      context 'when it raises a different error' do
        let(:error) { StandardError.new }

        it { expect { find_file }.to raise_error StandardError }
      end
    end
  end

  describe '#find_file!(id)' do
    subject(:find_file) { api.find_file!('file-id') }
    before  { allow(api).to receive(:default_file_fields).and_return 'default' }
    after   { find_file }

    it 'calls #get_file on drive service' do
      expect(drive_service)
        .to receive(:get_file)
        .with('file-id', fields: 'default')
    end
  end

  describe '#find_files_by_parent_id(parent_id)' do
    subject(:find_files)  { api.find_files_by_parent_id('parent-id') }
    let(:file_list)       { instance_double Google::Apis::DriveV3::FileList }
    before do
      allow(api).to receive(:default_file_fields).and_return 'default'
      allow(api)
        .to receive(:prefix_fields)
        .with('files', 'default')
        .and_return 'files/default'
      allow(drive_service)
        .to receive(:list_files)
        .with(q: "'parent-id' in parents", fields: 'files/default')
        .and_return file_list
      allow(file_list).to receive(:files).and_return %w[f1 f2 f3]
    end

    it { is_expected.to eq %w[f1 f2 f3] }
  end

  describe '#file_head_revision!(id)' do
    subject(:file_head_revision) { api.file_head_revision!('id') }
    let(:revision) { instance_double Google::Apis::DriveV3::Revision }

    before do
      allow(drive_service).to receive(:get_revision).and_return revision
      allow(revision).to receive(:id).and_return '123abcXZY'
    end

    it { is_expected.to eq '123abcXZY' }

    it 'calls #get_revision on drive service' do
      expect(drive_service).to receive(:get_revision).with('id', 'head')
      file_head_revision
    end
  end

  describe '#file_head_revision(id)' do
    subject(:file_head_revision) { api.file_head_revision('id') }
    before do
      allow(api).to receive(:file_head_revision!).with('id').and_return '12345'
    end

    it { is_expected.to eq '12345' }

    context 'when an error is raised' do
      before { allow(api).to receive(:file_head_revision!).and_raise error }

      context 'Google::Apis::ClientError, revisionsNotSupported' do
        let(:error) { Google::Apis::ClientError.new('revisionsNotSupported') }

        it { is_expected.to eq '1' }
      end

      context 'Google::Apis::ClientError, revisionsNotSupported' do
        let(:error) do
          Google::Apis::ClientError.new('insufficientFilePermissions')
        end

        it { is_expected.to eq '1' }
      end

      context 'Google::Apis::ClientError, revisionsNotSupported' do
        let(:error) do
          Google::Apis::ClientError.new('notFound: Revision not found')
        end

        it { is_expected.to eq '1' }
      end

      context 'Google::Apis::ClientError of different type' do
        let(:error) { Google::Apis::ClientError.new('invalid') }

        it do
          expect { file_head_revision }.to raise_error Google::Apis::ClientError
        end
      end

      context 'when it raises a different error' do
        let(:error) { StandardError.new }

        it { expect { file_head_revision }.to raise_error StandardError }
      end
    end
  end

  describe '#file_permission_id_by_email(id, email)' do
    subject(:file_permission_id) do
      api.file_permission_id_by_email('file-id', 'example@gmail.com')
    end
    let(:permission1) { permission.new(id: '1', email_address: 'a@b.com') }
    let(:permission2) do
      permission.new(id: 'permission-id', email_address: 'example@gmail.com')
    end
    let(:permission3) { permission.new(id: '3', email_address: 'a@b.com') }
    let(:permission)  { Google::Apis::DriveV3::Permission }
    after { file_permission_id }

    before do
      allow(api)
        .to receive(:list_file_permissions)
        .with('file-id')
        .and_return [permission1, permission2, permission3]
    end

    it { is_expected.to eq 'permission-id' }
  end

  describe '#list_changes(token, page_size = 100)' do
    subject(:list_changes) { api.list_changes('token') }
    let(:fields) do
      %w[nextPageToken newStartPageToken changes/file_id changes/file/parents]
        .join(',')
    end

    before do
      allow(drive_service)
        .to receive(:list_changes)
        .with('token', page_size: 100, fields: fields)
        .and_return 'change-list'
    end

    it { is_expected.to eq 'change-list' }
  end

  describe '#list_file_permissions(id)' do
    subject(:list_file_permissions) do
      api.list_file_permissions('file-id')
    end

    before do
      permission_list = instance_double Google::Apis::DriveV3::PermissionList
      allow(drive_service)
        .to receive(:list_permissions).and_return permission_list
      allow(permission_list).to receive(:permissions).and_return %w[p1 p2 p3]
    end

    it 'calls #list_permissions on drive service' do
      list_file_permissions
      expect(drive_service)
        .to have_received(:list_permissions)
        .with(
          'file-id',
          fields: 'permissions/id, permissions/emailAddress, permissions/type'
        )
    end

    it { is_expected.to eq %w[p1 p2 p3] }
  end

  describe '#refresh_authorization' do
    subject(:refresh_authorization) { api.refresh_authorization }
    let(:authorization) { instance_double Google::Auth::UserRefreshCredentials }
    after { refresh_authorization }

    before do
      allow(drive_service).to receive(:authorization).and_return authorization
    end

    it { expect(authorization).to receive(:refresh!) }
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

  describe '#share_file_with_anyone(id, role = :reader)' do
    subject(:share_file_with_anyone) { api.share_file_with_anyone('file-id') }
    after { share_file_with_anyone }

    it do
      expect(drive_service)
        .to receive(:create_permission)
        .with('file-id', instance_of(Google::Apis::DriveV3::Permission))
    end

    it 'calls #create_permission with type: anyone' do
      expect(drive_service).to receive(:create_permission) do |*args|
        expect(args[1].type).to eq 'anyone'
      end
    end

    it 'calls #create_permission with role: reader' do
      expect(drive_service).to receive(:create_permission) do |*args|
        expect(args[1].role).to eq 'reader'
      end
    end

    context 'when role is passed' do
      subject(:share_file_with_anyone) do
        api.share_file_with_anyone('id', 'custom-role')
      end

      it 'calls #create_permission with custom role' do
        expect(drive_service).to receive(:create_permission) do |*args|
          expect(args[1].role).to eq 'custom-role'
        end
      end
    end
  end

  describe '#start_token_for_listing_changes' do
    subject(:start_token) { api.start_token_for_listing_changes }
    before do
      token = instance_double Google::Apis::DriveV3::StartPageToken
      allow(drive_service)
        .to receive(:get_changes_start_page_token).and_return token
      allow(token).to receive(:start_page_token).and_return 'start-page-token'
    end

    it { is_expected.to eq 'start-page-token' }
  end

  describe '#thumbnail(url, size: 350)' do
    subject(:thumbnail) { api.thumbnail('url') }

    before do
      allow(api)
        .to receive(:add_query_parameters_to_url)
        .with('url', 'sz' => 's350')
        .and_return 'url-with-params'
    end

    it 'calls execute_api_command with :get and url with query params' do
      expect(api).to receive(:execute_api_command).with(:get, 'url-with-params')
      thumbnail
    end

    context 'when a Google::Apis::ClientError is raised' do
      before { allow(api).to receive(:execute_api_command).and_raise error }
      let(:error) { Google::Apis::ClientError.new('notFound') }

      it { is_expected.to eq nil }
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
              kind_of(Google::Apis::DriveV3::File),
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

  describe '#unshare_file_with_anyone(id)' do
    subject(:unshare_file_with_anyone) do
      api.unshare_file_with_anyone('file-id')
    end

    let(:permission1) { permission.new(id: '1', email_address: 'a@b.com') }
    let(:permission2) { permission.new(id: 'permission-id', type: 'anyone') }
    let(:permission3) { permission.new(id: '3', type: 'user') }
    let(:permission)  { Google::Apis::DriveV3::Permission }

    before do
      allow(api)
        .to receive(:list_file_permissions)
        .with('file-id')
        .and_return [permission1, permission2, permission3]
    end

    it do
      expect(drive_service)
        .to receive(:delete_permission).with('file-id', 'permission-id')
      unshare_file_with_anyone
    end

    context 'when permission of type anyone does not exist' do
      before { permission2.type = 'user' }

      it { is_expected.to be true }
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
              kind_of(Google::Apis::DriveV3::File),
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

  describe '#upload_file(name:, parent_id:, file:, mime_type:)' do
    subject(:upload_file) { api.upload_file(args) }
    let(:args) do
      { name: 'name', parent_id: 'parent-id', file: 'file', mime_type: 'doc' }
    end
    before  { allow(api).to receive(:default_file_fields).and_return 'default' }
    before  { allow(drive_service).to receive(:create_file) }
    before  { upload_file }

    it 'calls #create_file on drive service' do
      expect(drive_service)
        .to have_received(:create_file)
        .with(
          kind_of(Google::Apis::DriveV3::File),
          upload_source: 'file',
          content_type: 'doc',
          fields: 'default'
        )
    end

    it 'calls #create_file with name' do
      expect(drive_service)
        .to have_received(:create_file) do |*args|
        expect(args[0].name).to eq 'name'
      end
    end

    it 'calls #create_file with parent_id' do
      expect(drive_service)
        .to have_received(:create_file) do |*args|
        expect(args[0].parents.first).to eq 'parent-id'
      end
    end

    it 'calls #create_file with mime_type' do
      expect(drive_service)
        .to have_received(:create_file) do |*args|
        expect(args[0].mime_type).to eq 'doc'
      end
    end
  end

  describe '#add_query_parameters_to_url' do
    subject(:add) { api.send(:add_query_parameters_to_url, url, params) }
    let(:url)     { 'http://test.com/page?a=1&b=2&c=3' }
    let(:params)  { { 'd' => '4', 'e' => '5' } }

    it 'adds new params' do
      is_expected.to eq 'http://test.com/page?a=1&b=2&c=3&d=4&e=5'
    end

    context 'when params already exist in URL' do
      let(:params) { { 'a' => 'new', 'b' => 'new2' } }

      it 'overrides existing params' do
        is_expected.to eq 'http://test.com/page?a=new&b=new2&c=3'
      end
    end
  end

  describe '#default_file_fields' do
    subject(:default_file_fields) { api.send(:default_file_fields) }
    it { is_expected.to match 'id' }
    it { is_expected.to match 'name' }
    it { is_expected.to match 'mimeType' }
    it { is_expected.to match 'parents' }
    it { is_expected.to match 'trashed' }
    it { is_expected.to match 'thumbnailLink' }
    it { is_expected.to match 'thumbnailVersion' }
  end

  describe '#execute_api_command(method, url)' do
    subject(:execute) { api.send(:execute_api_command, 'method', 'url') }
    let(:command)     { instance_double Google::Apis::Core::ApiCommand }

    before do
      allow(Google::Apis::Core::ApiCommand)
        .to receive(:new).with('method', 'url').and_return command
      allow(command).to receive(:options=)
      allow(drive_service).to receive(:request_options).and_return 'request-ops'
      allow(command).to receive(:execute)
      allow(drive_service).to receive(:client).and_return 'client'
    end

    after { execute }

    it 'sets request_options on command' do
      expect(command).to receive(:options=).with 'request-ops'
    end

    it 'calls execute with drive service client on command' do
      expect(command).to receive(:execute).with('client')
    end
  end

  describe '#prefix_fields(prefix, fields)' do
    subject(:prefix_fields) { api.send(:prefix_fields, 'prefix', 'f1,f2,f3') }

    it { is_expected.to eq 'prefix/f1,prefix/f2,prefix/f3' }
  end
end
