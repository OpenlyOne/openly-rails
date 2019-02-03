# frozen_string_literal: true

RSpec.describe Providers::GoogleDrive::FileSync, type: :model do
  subject(:file_sync) { Providers::GoogleDrive::FileSync.new('id') }
  let(:api)           { instance_double Providers::GoogleDrive::ApiConnection }

  before do
    allow(Providers::GoogleDrive::FileSync)
      .to receive(:default_api_connection).and_return(api)
  end

  describe 'attributes' do
    it { is_expected.to respond_to :id }
    it { is_expected.to respond_to :name }
    it { is_expected.to respond_to :parent_id }
  end

  describe '.create(name:, parent_id:, mime_type:, api_connection:)' do
    subject(:create_sync) { described_class.create(args) }
    let(:args)  { { name: 'name', parent_id: 'parent-id', mime_type: 'doc' } }
    let(:file)  { instance_double Providers::GoogleDrive::File }

    before { allow(api).to receive(:create_file).and_return file }
    before { allow(file).to receive(:id).and_return 'file-id' }
    before { allow(described_class).to receive(:new) }

    it 'calls API#create_file with args' do
      expect(api).to receive(:create_file).with(args)
      create_sync
    end

    it 'returns new instance of FileSync' do
      expect(described_class)
        .to receive(:new)
        .with('file-id', file: file, api_connection: api)
        .and_return('new_instance')
      is_expected.to eq 'new_instance'
    end

    context 'when api_connection is passed' do
      let(:custom_api) { instance_double Providers::GoogleDrive::ApiConnection }
      before { args.merge!(api_connection: custom_api) }
      before { allow(custom_api).to receive(:create_file).and_return file }

      it 'calls #create_file on custom api connection' do
        expect(custom_api).to receive(:create_file)
        create_sync
      end

      it 'returns new instance of FileSync with custom api' do
        expect(described_class)
          .to receive(:new)
          .with('file-id', hash_including(api_connection: custom_api))
          .and_return('new_instance')
        is_expected.to eq 'new_instance'
      end
    end
  end

  describe '.upload(name:, parent_id:, file:, mime_type:, ...)' do
    subject(:upload_sync) { described_class.upload(args) }
    let(:args) do
      { name: 'name', parent_id: 'parent-id', file: 'file', mime_type: 'doc' }
    end
    let(:file) { instance_double Providers::GoogleDrive::File }

    before { allow(api).to receive(:upload_file).and_return file }
    before { allow(file).to receive(:id).and_return 'file-id' }
    before { allow(described_class).to receive(:new) }

    it 'calls API#upload_file with args' do
      expect(api).to receive(:upload_file).with(args)
      upload_sync
    end

    it 'returns new instance of FileSync' do
      expect(described_class)
        .to receive(:new)
        .with('file-id', file: file, api_connection: api)
        .and_return('new_instance')
      is_expected.to eq 'new_instance'
    end

    context 'when api_connection is passed' do
      let(:custom_api) { instance_double Providers::GoogleDrive::ApiConnection }
      before { args.merge!(api_connection: custom_api) }
      before { allow(custom_api).to receive(:upload_file).and_return file }

      it 'calls #create_file on custom api connection' do
        expect(custom_api).to receive(:upload_file)
        upload_sync
      end

      it 'returns new instance of FileSync with custom api' do
        expect(described_class)
          .to receive(:new)
          .with('file-id', hash_including(api_connection: custom_api))
          .and_return('new_instance')
        is_expected.to eq 'new_instance'
      end
    end
  end

  describe '#initialize' do
    subject(:method)  { described_class.new('id', arguments) }
    let(:arguments)   { {} }

    context 'when file is nil' do
      before { arguments[:file] = nil }

      it { is_expected.to be_deleted }
    end

    context 'when file is trashed' do
      let(:file)  { Providers::GoogleDrive::File.new(trashed: true) }
      before      { arguments[:file] = file }

      it { is_expected.to be_deleted }
    end
  end

  describe '#children' do
    subject(:children)  { file_sync.children }
    let(:children_ivar) { 'children' }
    before { file_sync.instance_variable_set :@children, children_ivar }

    it { is_expected.to eq 'children' }

    context 'when @children is not is set' do
      let(:children_ivar) { nil }
      after { children }

      it { expect(file_sync).to receive(:fetch_children_as_file_syncs) }
    end
  end

  describe '#content_version' do
    subject(:content_version)   { file_sync.content_version }
    let(:content_version_ivar)  { 'version' }
    let(:deleted)               { false }
    before do
      allow(file_sync).to receive(:deleted?).and_return deleted
      file_sync.instance_variable_set :@content_version, content_version_ivar
    end

    it { is_expected.to eq 'version' }

    context 'when @content_version is not is set' do
      let(:content_version_ivar) { nil }
      after { content_version }

      it { expect(file_sync).to receive(:fetch_content_version) }
    end

    context 'when deleted? returns true' do
      let(:deleted) { true }

      it { is_expected.to be nil }
    end
  end

  describe '#deleted?' do
    let(:file)      { Google::Apis::DriveV3::File.new }
    before          { allow(file_sync).to receive(:file).and_return file }

    it { is_expected.not_to be_deleted }

    context 'when file is trashed' do
      before { file.trashed = true }

      it { is_expected.to be_deleted }
    end
  end

  describe '#download' do
    subject(:download) { file_sync.download }

    before do
      type = instance_double Providers::GoogleDrive::MimeType
      allow(file_sync).to receive(:mime_type).and_return 'mime-type'
      allow(Providers::GoogleDrive::MimeType)
        .to receive(:new).with('mime-type').and_return type
      allow(type).to receive(:exportable?).and_return is_exportable
      allow(type).to receive(:export_as).and_return 'format'
      allow(api).to receive(:export_file)
      allow(api).to receive(:download_file)
    end

    context 'when file is exportable' do
      let(:is_exportable) { true }

      it 'calls #export_file' do
        download
        expect(api).to have_received(:export_file).with('id', format: 'format')
      end
    end

    context 'when file is not exportable' do
      let(:is_exportable) { false }

      it 'calls #download_file' do
        download
        expect(api).to have_received(:download_file).with('id')
      end
    end
  end

  describe '#duplicate(name:, parent_id:)' do
    subject(:duplicate) { file_sync.duplicate(name: 'abc', parent_id: 'p-id') }

    let(:file) { Google::Apis::DriveV3::File.new(id: 'dup-id') }

    before  { file_sync.instance_variable_set :@id, 'id' }
    before  { allow(api).to receive(:duplicate_file).and_return file }
    after   { duplicate }

    it 'duplicates the file' do
      duplicate
      expect(api)
        .to have_received(:duplicate_file)
        .with('id', name: 'abc', parent_id: 'p-id')
    end

    it 'returns new instance with dup-id and @file' do
      expect(duplicate).to be_an_instance_of(described_class)
      expect(duplicate).not_to equal file_sync
      expect(duplicate.id).to eq 'dup-id'
      expect(duplicate.instance_variable_get(:@file)).to be_present
    end
  end

  describe '#grant_read_access_to(email)' do
    subject(:grant_access) { file_sync.grant_read_access_to('em@il') }

    before do
      allow(file_sync).to receive(:id).and_return 'id'
      allow(api).to receive(:share_file)
    end

    it do
      grant_access
      expect(api).to have_received(:share_file).with('id', 'em@il', :reader)
    end
  end

  describe '#grant_write_access_to(email)' do
    subject(:grant_access) { file_sync.grant_write_access_to('em@il') }

    before do
      allow(file_sync).to receive(:id).and_return 'id'
      allow(api).to receive(:share_file)
    end

    it do
      grant_access
      expect(api).to have_received(:share_file).with('id', 'em@il', :writer)
    end
  end

  describe '#mime_type' do
    subject(:mime_type) { file_sync.mime_type }
    let(:file)          { Google::Apis::DriveV3::File.new(mime_type: 'type') }
    before              { allow(file_sync).to receive(:file).and_return file }

    it { is_expected.to eq 'type' }

    context 'when file is not is set' do
      let(:file) { nil }

      it { is_expected.to eq nil }
    end
  end

  describe '#name' do
    subject(:name)  { file_sync.name }
    let(:file)      { Google::Apis::DriveV3::File.new(name: 'file-name') }
    before          { allow(file_sync).to receive(:file).and_return file }

    it { is_expected.to eq 'file-name' }

    context 'when file is not is set' do
      let(:file) { nil }

      it { is_expected.to eq nil }
    end
  end

  describe '#parent_id' do
    subject(:parent_id) { file_sync.parent_id }
    let(:file)          { Google::Apis::DriveV3::File.new(parents: parents) }
    let(:parents)       { ['file-parent-id'] }
    before              { allow(file_sync).to receive(:file).and_return file }

    it { is_expected.to eq 'file-parent-id' }

    context 'when file parents are nil' do
      let(:parents) { nil }

      it { is_expected.to eq nil }
    end

    context 'when file is nil' do
      let(:file) { nil }

      it { is_expected.to eq nil }
    end
  end

  describe '#permissions' do
    subject(:permissions) { file_sync.permissions }

    let(:file)  { Google::Apis::DriveV3::File.new(permissions: [p1, p2]) }
    let(:p1)    { instance_double Google::Apis::DriveV3::Permission }
    let(:p2)    { instance_double Google::Apis::DriveV3::Permission }

    before { allow(file_sync).to receive(:file).and_return file }

    it { is_expected.to contain_exactly(p1, p2) }

    context 'when file is not is set' do
      let(:file) { nil }

      it { is_expected.to eq nil }
    end
  end

  describe '#reload' do
    subject(:reload) { file_sync.reload }

    let(:instance_variables) do
      %i[@capabilities @children @content @content_version @file @thumbnail]
    end

    it 'resets all instance variables' do
      instance_variables.each do |variable|
        file_sync.instance_variable_set(variable, 'content')
      end
      reload
      instance_variables.each do |variable|
        expect(file_sync.instance_variable_get(variable)).to eq nil
      end
    end

    it 'returns self for chaining' do
      is_expected.to be file_sync
    end
  end

  describe '#relocate(to:, from:)' do
    subject(:relocate) { file_sync.relocate(to: 'to', from: 'from') }
    before  { file_sync.instance_variable_set :@id, 'id' }
    before  { allow(api).to receive(:update_file_parents).and_return 'file' }
    after   { relocate }

    it do
      expect(api)
        .to receive(:update_file_parents)
        .with('id', add: ['to'], remove: ['from'])
    end

    it 'sets instance variable @file' do
      subject
      expect(file_sync.instance_variable_get(:@file)).to be_present
    end
  end

  describe '#rename(name)' do
    subject(:rename) { file_sync.rename('new-name') }
    before  { file_sync.instance_variable_set :@id, 'id' }
    before  { allow(api).to receive(:update_file_name).and_return 'file' }
    after   { rename }

    it { expect(api).to receive(:update_file_name).with('id', 'new-name') }

    it 'sets instance variable @file' do
      subject
      expect(file_sync.instance_variable_get(:@file)).to be_present
    end
  end

  describe '#revoke_access_from(email)' do
    subject(:revoke_access) { file_sync.revoke_access_from('em@il') }

    before do
      allow(file_sync).to receive(:id).and_return 'id'
      allow(api).to receive(:unshare_file)
    end

    it do
      revoke_access
      expect(api).to have_received(:unshare_file).with('id', 'em@il')
    end
  end

  describe '#switch_api_connection(api_connection)' do
    subject(:switch) { file_sync.switch_api_connection('new-connection') }

    it do
      switch
      expect(file_sync.send(:api_connection)).to eq 'new-connection'
    end
  end

  describe '#thumbnail' do
    subject(:thumbnail)   { file_sync.thumbnail }
    let(:thumbnail_ivar)  { 'thumbnail' }
    let(:has_thumbnail)   { true }
    before do
      allow(file_sync).to receive(:thumbnail?).and_return has_thumbnail
      file_sync.instance_variable_set :@thumbnail, thumbnail_ivar
    end

    it { is_expected.to eq 'thumbnail' }

    context 'when @thumbnail is not is set' do
      let(:thumbnail_ivar) { nil }
      after { thumbnail }

      it { expect(file_sync).to receive(:fetch_thumbnail) }
    end

    context 'when thumbnail? returns false' do
      let(:has_thumbnail) { false }

      it { is_expected.to be nil }
    end
  end

  describe '#thumbnail_version' do
    subject(:thumbnail_version) { file_sync.thumbnail_version }
    let(:file) { Google::Apis::DriveV3::File.new(thumbnail_version: 'v1') }
    before     { allow(file_sync).to receive(:file).and_return file }

    it { is_expected.to eq 'v1' }

    context 'when file is not is set' do
      let(:file)  { nil }
      it          { is_expected.to eq nil }
    end
  end

  describe '#thumbnail?' do
    subject(:thumbnail) { file_sync.thumbnail? }
    let(:link)          { 'link' }
    let(:deleted)       { false }
    before     { allow(file_sync).to receive(:deleted?).and_return deleted }
    before     { allow(file_sync).to receive(:thumbnail_link).and_return link }

    it { is_expected.to be true }

    context 'when thumbnail_link is nil' do
      let(:link)  { nil }
      it          { is_expected.to be false }
    end

    context 'when deleted? returns true' do
      let(:deleted) { true }
      it            { is_expected.to be false }
    end
  end

  describe '#fetch_file' do
    subject(:fetch_file)  { file_sync.send(:fetch_file) }
    after                 { fetch_file }

    before do
      allow(file_sync).to receive(:id).and_return 'id'
      allow(api).to receive(:find_file).with('id').and_return 'found-file'
    end

    it { expect(file_sync).to receive(:file=).with('found-file') }
  end

  describe '#file' do
    subject(:file)  { file_sync.send(:file) }
    let(:file_ivar) { 'file' }
    before          { file_sync.instance_variable_set :@file, file_ivar }

    it { is_expected.to eq 'file' }

    context 'when file is not set' do
      let(:file_ivar) { nil }

      before do
        allow(file_sync).to receive(:fetch_file) do
          file_sync.instance_variable_set :@file, 'fetched-file'
          'output'
        end
      end

      it 'calls #fetch_file' do
        expect(file_sync).to receive(:fetch_file)
        file
      end

      it { is_expected.to eq 'fetched-file' }
    end
  end

  describe '#file=' do
    subject(:file)      { file_sync.send(:file=, 'file') }
    let(:file_deleted)  { false }
    before do
      allow(Providers::GoogleDrive::File)
        .to receive(:deleted?).with('file').and_return file_deleted
    end

    it 'sets @file instance variable to file' do
      file
      expect(file_sync.instance_variable_get(:@file)).to eq 'file'
    end

    context 'when file is deleted' do
      let(:file_deleted) { true }

      it 'sets @file instance variable to new file' do
        allow(Providers::GoogleDrive::File).to receive(:new).and_return 'new-f'
        file
        expect(file_sync.instance_variable_get(:@file)).to eq 'new-f'
      end
    end
  end
end
