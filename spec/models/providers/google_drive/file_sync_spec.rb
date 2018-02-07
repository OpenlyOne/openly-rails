# frozen_string_literal: true

RSpec.describe Providers::GoogleDrive::FileSync, type: :model do
  subject(:file_sync) { Providers::GoogleDrive::FileSync.new }
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
    let(:args) { { name: 'name', parent_id: 'parent-id', mime_type: 'doc' } }

    before { allow(api).to receive(:create_file).and_return 'file' }

    it 'calls API#create_file with args' do
      expect(api).to receive(:create_file).with(args)
      create_sync
    end

    it 'returns new instance of FileSync' do
      allow(described_class)
        .to receive(:new)
        .with(file: 'file', api_connection: api)
        .and_return('new_instance')
      is_expected.to eq 'new_instance'
    end

    context 'when api_connection is passed' do
      let(:custom_api) { instance_double Providers::GoogleDrive::ApiConnection }
      before { args.merge!(api_connection: custom_api) }
      before { allow(custom_api).to receive(:create_file).and_return 'file' }

      it 'calls #create_file on custom api connection' do
        expect(custom_api).to receive(:create_file)
        create_sync
      end

      it 'returns new instance of FileSync with custom api' do
        allow(described_class)
          .to receive(:new)
          .with(hash_including(api_connection: custom_api))
          .and_return('new_instance')
        is_expected.to eq 'new_instance'
      end
    end
  end

  describe '#id' do
    subject(:id)  { file_sync.id }
    let(:id_ivar) { 'id' }
    let(:file)    { Google::Apis::DriveV3::File.new(id: 'file-id') }
    before        { file_sync.instance_variable_set :@id, id_ivar }
    before        { allow(file_sync).to receive(:file).and_return file }

    it { is_expected.to eq 'id' }

    context 'when id is not set but file is set' do
      let(:id_ivar) { nil }
      it            { is_expected.to eq 'file-id' }
    end

    context 'when neither file nor id is set' do
      let(:id_ivar) { nil }
      let(:file)    { nil }

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

  describe '#file' do
    subject(:file)  { file_sync.send(:file) }
    let(:file_ivar) { 'file' }
    before          { file_sync.instance_variable_set :@file, file_ivar }

    it { is_expected.to eq 'file' }

    context 'when file is not set' do
      let(:file_ivar) { nil }
      before          { file_sync.instance_variable_set :@id, 'id' }
      before { allow(api).to receive(:fetch_file).and_return 'fetched-file' }

      it 'calls api#fetch_file with @id' do
        expect(api).to receive(:fetch_file).with('id')
        file
      end

      it 'returns fetched file' do
        is_expected.to eq 'fetched-file'
      end

      it 'sets instance variable @file' do
        file
        expect(file_sync.instance_variable_get(:@file)).to be_present
      end
    end
  end
end
