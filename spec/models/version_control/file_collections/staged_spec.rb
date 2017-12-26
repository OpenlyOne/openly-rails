# frozen_string_literal: true

require 'models/shared_examples/version_control/using_repository_locking.rb'

RSpec.describe VersionControl::FileCollections::Staged, type: :model do
  subject(:file_collection) { repository.stage.files }
  let(:repository)          { build :repository }
  let(:root)                { create :file, :root, repository: repository }

  describe '#count' do
    subject(:method) { file_collection.count }

    it_should_behave_like 'using repository locking' do
      let(:locker) { file_collection }
    end

    context 'without root' do
      it { is_expected.to eq 0 }
    end

    context 'with root' do
      before  { create_list :file, 0, parent: root }
      it      { is_expected.to eq 1 }
    end

    context 'with 3 files' do
      before  { create_list :file, 3, parent: root }
      it      { is_expected.to eq 4 }
    end
  end

  describe '#create_or_update(params)' do
    subject(:method)  { file_collection.create_or_update(params) }
    let!(:root)       { create :file, :root, repository: repository }
    let(:file_id)     { 'azzouqhpgyde3275367310' }
    let(:params) do
      {
        id: file_id,
        name: 'my file',
        mime_type: 'application/vnd.google-apps.document',
        parent_id: root.id,
        version: 5,
        modified_time: Time.zone.now
      }
    end
    let(:saved_file) { file_collection.find(params[:id]) }

    it_should_behave_like 'using repository locking' do
      let(:locker) { file_collection }
    end

    context 'when file does not yet exist' do
      it 'creates file with the id' do
        method
        expect(file_collection.find(params[:id]))
          .to be_an_instance_of VersionControl::Files::Staged
      end
    end

    context 'when file already exists' do
      let(:file)    { create :file, parent: root }
      let(:file_id) { file.id }

      it 'calls #update on the file' do
        expect_any_instance_of(VersionControl::Files::Staged)
          .to receive(:update).with(params)
        method
      end

      context 'when file is root' do
        let(:file_id) { root.id }

        it 'calls #update on root' do
          expect_any_instance_of(VersionControl::Files::Staged::Root)
            .to receive(:update).with(params)
          method
        end
      end
    end
  end

  describe '#create_root' do
    subject(:method) { file_collection.create_root(params) }
    let(:params) do
      {
        id: '123-abc-root-id',
        name: 'my file',
        mime_type: 'application/vnd.google-apps.folder',
        version: 5,
        modified_time: Time.zone.now
      }
    end

    it_should_behave_like 'using repository locking' do
      let(:locker) { file_collection }
    end

    it { is_expected.to be_an_instance_of VersionControl::Files::Staged::Root }

    it 'creates a root folder' do
      method
      expect(file_collection.root).to have_attributes(params)
    end

    context 'when root already exists' do
      let!(:root) { create :file, :root, repository: repository }

      it 'raises ActiveRecord::RecordInvalid error' do
        expect { method }.to raise_error ActiveRecord::RecordInvalid
      end
    end
  end

  describe '#exists?(id)' do
    subject(:method)  { file_collection.exists? file_id }
    let(:file_id)     { 'abc' }

    it_should_behave_like 'using repository locking' do
      let(:locker) { file_collection }
    end

    context 'when file with id exists' do
      before do
        FileUtils.touch(::File.expand_path(file_id, file_collection.workdir))
      end
      it { is_expected.to be true }
    end

    context 'when file with id does not exist' do
      it { is_expected.to be false }
    end
  end

  describe '#find(id)' do
    subject(:method)  { file_collection.find file_id }
    let(:file_id)     { file.id }
    let(:file)        { create :file, parent: root }

    it_should_behave_like 'using repository locking' do
      before        { file }
      let(:locker)  { file_collection }
    end
    it { is_expected.to be_a VersionControl::Files::Staged }
    it do
      is_expected.to have_attributes(
        id: file.id,
        name: file.name,
        mime_type: file.mime_type,
        parent_id: file.parent_id,
        version: file.version,
        modified_time: file.modified_time
      )
    end

    context 'when id is root' do
      let(:file_id) { root.id }
      it 'returns an instance of root' do
        expect(method).to be_an_instance_of VersionControl::Files::Staged::Root
      end
    end

    context 'when id is nil' do
      let(:file_id) { nil }

      it 'raises ActiveRecord::RecordNotFound error' do
        expect { method }.to raise_error(
          ActiveRecord::RecordNotFound,
          "Couldn't find file with id: #{file_id}"
        )
      end
    end

    context 'when id is non existent' do
      let(:file_id) { 'non-existent-file' }

      it 'raises ActiveRecord::RecordNotFound error' do
        expect { method }.to raise_error(
          ActiveRecord::RecordNotFound,
          "Couldn't find file with id: #{file_id}"
        )
      end
    end
  end

  describe 'path_for_file(id)' do
    subject(:method)  { file_collection.send :path_for_file, id }
    let(:basename)    { 'new-file' }
    let(:id)          { "#{basename}-1" }
    let(:path)        { File.expand_path(id, repository.workdir) }
    before            { FileUtils.mkdir_p(path) if id.present? }

    it_should_behave_like 'using repository locking' do
      let(:locker) { file_collection }
    end
    it { is_expected.to eq path }

    context 'when second file with similar id exists' do
      let(:id_2)    { basename }
      let(:path_2)  { File.expand_path(id_2, repository.workdir) }
      before        { FileUtils.mkdir_p path_2 }

      it 'only returns exact matches' do
        expect(subject).to eq path
        expect(file_collection.send(:path_for_file, id_2)).to eq path_2
      end
    end

    context 'when file does not exist' do
      before { FileUtils.remove_dir(path) }

      it 'raises a file not found error' do
        expect { method }.to raise_error(
          Errno::ENOENT,
          'No such file or directory - ' \
          "File named #{id} does not exist in " \
          "#{Pathname(repository.workdir).cleanpath}"
        )
      end
    end

    context 'when file is nil' do
      let(:id) { nil }
      it 'raises a invalid argument error' do
        expect { method }.to raise_error(
          Errno::EINVAL,
          'Invalid argument - ID must be a String.'
        )
      end
    end
  end

  describe '#root' do
    subject(:method) { file_collection.root }

    it_should_behave_like 'using repository locking' do
      let(:locker) { file_collection }
    end

    context 'when root exists' do
      let!(:root) { create :file, :root, repository: repository }
      it do
        is_expected.to be_an_instance_of VersionControl::Files::Staged::Root
      end
      it { is_expected.to have_attributes(id: root.id, name: root.name) }
    end

    context 'when root does not exist' do
      it { is_expected.to be nil }
    end
  end

  describe '#root_id' do
    subject(:method)  { file_collection.root_id }
    let(:root_id)     { 'abc' }
    let(:path)        { ::File.expand_path root_id, repository.workdir }

    it_should_behave_like 'using repository locking' do
      let(:locker) { file_collection }
    end

    context 'when root exists' do
      before { FileUtils.touch path }
      it { is_expected.to eq root_id }
    end

    context 'when root does not exist' do
      it { is_expected.to be nil }
    end
  end

  describe '#metadata_for(id)' do
    subject(:method)  { file_collection.send :metadata_for, file_id }
    let(:file_id)     { root.id }

    it_should_behave_like 'using repository locking' do
      before        { root }
      let(:locker)  { file_collection }
    end

    context 'when id is root id' do
      let(:file_id) { root.id }
      it do
        is_expected.to eq(
          id: root.id,
          name: root.name,
          mime_type: root.mime_type,
          parent_id: nil,
          version: root.version,
          modified_time: root.modified_time,
          is_root: true
        )
      end
    end

    context 'when id is file id' do
      let(:file_id) { file.id }
      let(:folder)  { create :file, :folder, parent: root }
      let(:file)    { create :file, parent: folder }

      it do
        is_expected.to eq(
          id: file.id,
          name: file.name,
          mime_type: file.mime_type,
          parent_id: folder.id,
          version: file.version,
          modified_time: file.modified_time,
          is_root: false
        )
      end
    end

    context 'when id is folder id' do
      let(:file_id) { folder.id }
      let(:folder)  { create :file, :folder, parent: root }

      it do
        is_expected.to eq(
          id: folder.id,
          name: folder.name,
          mime_type: folder.mime_type,
          parent_id: root.id,
          version: folder.version,
          modified_time: folder.modified_time,
          is_root: false
        )
      end
    end
  end

  describe '#parent_id_from_file_path(path)' do
    subject(:method) { file_collection.send :parent_id_from_file_path, path }

    context 'when path is :working_directory:/abc/def' do
      let(:path)  { ::File.expand_path('abc/def', file_collection.workdir) }
      it          { is_expected.to eq 'abc' }
    end

    context 'when path is :working_directory:/abc/def/ghi' do
      let(:path)  { ::File.expand_path('abc/def/ghi', file_collection.workdir) }
      it          { is_expected.to eq 'def' }
    end

    context 'when path is in :working_directory:/abc' do
      let(:path)  { ::File.expand_path('abc', file_collection.workdir) }
      it          { is_expected.to eq nil }
    end
  end
end
