# frozen_string_literal: true

require 'models/shared_examples/caching_method_call.rb'
require 'models/shared_examples/version_control/using_repository_locking.rb'

RSpec.shared_examples 'being a staged folder' do
  describe 'class' do
    it { is_expected.to be_kind_of VersionControl::Files::Staged::Folder }
  end

  describe '#children' do
    subject(:method)  { folder.children }
    let(:repository)  { folder.file_collection.repository }
    it { is_expected.to be_an Array }
    it { is_expected.to be_empty }

    context 'when folder has children' do
      before        { folder.send :create }
      let!(:files)  { create_list :file, 3, parent: folder }
      it            { expect(method.map(&:id)).to match_array(files.map(&:id)) }

      it_should_behave_like 'using repository locking' do
        let(:locker) { folder }
      end

      it_behaves_like 'caching method call', :children do
        subject { folder }
      end
    end
  end

  describe '#metadata_path' do
    subject(:method) { folder.send(:metadata_path) }

    context 'when path is abc/def/ghi' do
      before  { allow(folder).to receive(:path).and_return('abc/def/ghi') }
      it      { is_expected.to eq 'abc/def/ghi/.self' }
    end

    context 'when path is 123z54yBB' do
      before  { allow(folder).to receive(:path).and_return('123z54yBB') }
      it      { is_expected.to eq '123z54yBB/.self' }
    end

    context 'when path is nil' do
      before  { allow(folder).to receive(:path).and_return(nil) }
      it      { is_expected.to eq nil }
    end
  end

  describe '#create' do
    subject(:method)  { folder.send :create }
    let(:repository)  { folder.file_collection.repository }

    it_should_behave_like 'using repository locking' do
      let(:locker) { folder }
    end

    it 'creates a directory' do
      method
      path = folder.send(:path)
      expect(::File).to be_directory(path)
    end

    it 'writes metadata to .self' do
      method
      path = ::File.expand_path('.self', folder.send(:path))
      metadata = YAML.load_file(path).symbolize_keys
      expect(metadata).to match folder.send(:metadata)
    end

    context 'when directory with ID already exists' do
      before do
        folder.send :create
        FileUtils.touch(::File.expand_path('1.txt', folder.send(:path)))
        FileUtils.touch(::File.expand_path('2.txt', folder.send(:path)))
        FileUtils.touch(::File.expand_path('3.txt', folder.send(:path)))
      end

      it 'raises Errno::EEXIST error' do
        expect { method }.to raise_error(Errno::EEXIST)
      end

      it 'does not overwrite directory' do
        entries_before = Dir[folder.send(:path)]
        begin
          method
        rescue Errno::EEXIST
          entries_after = Dir[folder.send(:path)]
          expect(entries_after).to eq entries_before
        end
      end

      it 'does not overwrite metadata' do
        path = ::File.expand_path('.self', folder.send(:path))
        metadata_before = YAML.load_file(path).symbolize_keys
        begin
          method
        rescue Errno::EEXIST
          metadata_after = YAML.load_file(path).symbolize_keys
          expect(metadata_after).to eq metadata_before
        end
      end
    end
  end
end
