# frozen_string_literal: true

require 'models/shared_examples/version_control/being_a_file_collection.rb'

RSpec.describe VersionControl::FileCollections::Committed, type: :model do
  subject(:file_collection) do
    create_revision
    repository.revisions.last.files
  end
  let(:repository)      { build :repository }
  let(:create_revision) { create :revision, repository: repository }
  let(:root)            { create :file, :root, repository: repository }

  it_should_behave_like 'being a file collection'

  describe 'delegations' do
    it 'delegates lookup to repository' do
      subject
      expect_any_instance_of(VersionControl::Repository).to receive :lookup
      subject.lookup nil
    end
  end

  describe '#exists?(id_or_ids)' do
    subject(:method)  { file_collection.exists? id }
    let(:id)          { file.id }
    let!(:file)       { create :file, parent: root }

    it { is_expected.to be true }

    context 'when file with id does not exist' do
      let(:id)  { 'does-not-exist' }
      it        { is_expected.to be false }
    end

    context 'when id is nil' do
      let(:id)  { nil }
      it        { is_expected.to be false }
    end

    context 'when multiple ids are passed' do
      let(:id) { [file.id, root.id] }

      it { is_expected.to be_a Hash }

      it 'returns true for file and root' do
        expect(method).to eq file.id => true, root.id => true
      end

      context 'when single id as array is passed' do
        let(:id) { [file.id] }

        it { is_expected.to be_a Hash }
        it { expect(method).to eq file.id => true }
      end

      context 'when some elements are nil' do
        let(:id) { [file.id, nil, root.id, nil] }

        it 'drops nil and returns true for file and root ' do
          expect(method).to eq file.id => true, root.id => true
        end
      end

      context 'when some elements are non-existent' do
        let(:id) { [file.id, 'fail', root.id, 'does not exist'] }

        it 'returns true for file and root and false for others' do
          is_expected.to include(
            file.id           =>  true,
            'fail'            =>  false,
            root.id           =>  true,
            'does not exist'  =>  false
          )
        end
      end
    end
  end

  describe '#find_by_entry(entry)' do
    subject(:method)  { file_collection.find_by_entry(entry) }
    let(:entry)       { tree.get_entry(root.id).merge(path: root.id.to_s) }
    let(:tree)        { repository.revisions.last.tree }
    before            { root }
    before            { file_collection }

    it { is_expected.to be_a VersionControl::Files::Committed }
    it 'passes all parameters' do
      expect(VersionControl::Files::Committed).to receive(:new).with(
        file_collection,
        id: root.id,
        name: root.name,
        mime_type: root.mime_type,
        version: root.version,
        modified_time: root.modified_time,
        parent_id: nil,
        path: root.id,
        git_oid: kind_of(String)
      )
      subject
    end

    context 'when entry is nil' do
      let(:entry) { nil }
      it          { is_expected.to be nil }
    end

    context 'when entry is non existent' do
      before  { entry[:oid] = 'does-not-exist-here' }
      it      { is_expected.to be nil }
    end
  end

  describe '#find_by_id(id_or_ids)' do
    subject(:method)  { file_collection.find_by_id(id) }
    let(:id)          { file.id }
    let!(:file)       { create :file, parent: root }

    it { is_expected.to be_a VersionControl::Files::Committed }
    it { is_expected.to have_attributes(id: file.id, name: file.name) }

    context 'when file is a folder' do
      let!(:file) { create :file, :folder, parent: root }

      it { is_expected.to be_a VersionControl::Files::Committed }
      it { is_expected.to have_attributes(id: file.id, name: file.name) }
    end

    context 'when file with id does not exist' do
      let(:id)  { 'abc-does-not-exist' }
      it        { is_expected.to be nil }
    end

    context 'when id is nil' do
      let(:id)  { nil }
      it        { is_expected.to be nil }
    end

    context 'when multiple ids are passed' do
      let(:id) { [file.id, root.id] }

      it { is_expected.to be_an Array }

      it 'returns file and root' do
        expect(method.map(&:id)).to eq [file.id, root.id]
      end

      context 'when single id as array is passed' do
        let(:id) { [file.id] }

        it { is_expected.to be_an Array }
        it { expect(method[0].id).to eq file.id }
      end

      context 'when some elements are nil' do
        let(:id) { [file.id, nil, root.id, nil] }

        it 'returns file, nil, file, and nil' do
          expect(method[0]).to be_a VersionControl::File
          expect(method[1]).to be nil
          expect(method[2]).to be_a VersionControl::File
          expect(method[3]).to be nil
        end
      end

      context 'when some elements are non-existent' do
        let(:id) { [file.id, 'fail', root.id, 'does not exist'] }

        it 'returns file, nil, file, and nil' do
          expect(method[0]).to be_a VersionControl::File
          expect(method[1]).to be nil
          expect(method[2]).to be_a VersionControl::File
          expect(method[3]).to be nil
        end
      end
    end
  end

  describe '#find_by_path(path_or_paths)' do
    subject(:method)  { file_collection.find_by_path(path) }
    let(:path)        { 'root/file' }
    let(:root)  { create :file, :root, id: 'root', repository: repository }
    let!(:file) { create :file, id: 'file', parent: root }

    it { is_expected.to be_a VersionControl::Files::Committed }
    it { is_expected.to have_attributes(id: file.id, name: file.name) }

    context 'when path is nil' do
      let(:path)  { nil }
      it          { is_expected.to be nil }
    end

    context 'when multiple paths are passed' do
      let(:path) { ['root/file', 'root'] }

      it { is_expected.to be_an Array }

      it 'returns file and root' do
        expect(method.map(&:id)).to eq [file.id, root.id]
      end

      context 'when single path as array is passed' do
        let(:path) { ['root/file'] }

        it { is_expected.to be_an Array }
        it { expect(method[0].id).to eq file.id }
      end

      context 'when some elements are nil' do
        let(:path) { ['root/file', nil, 'root', nil] }

        it 'returns file, nil, file, and nil' do
          expect(method[0]).to be_a VersionControl::File
          expect(method[1]).to be nil
          expect(method[2]).to be_a VersionControl::File
          expect(method[3]).to be nil
        end
      end

      context 'when some elements are non-existent' do
        let(:path) { ['root/file', 'fail', 'root', 'does not exist'] }

        it 'returns file, nil, file, and nil' do
          expect(method[0]).to be_a VersionControl::File
          expect(method[1]).to be nil
          expect(method[2]).to be_a VersionControl::File
          expect(method[3]).to be nil
        end
      end
    end
  end

  describe '#find_entries_by_paths(paths)' do
    subject(:method) do
      file_collection.send :find_entries_by_paths, paths
    end
    let(:root)      { create :file, :root, id: 'root', repository: repository }
    let(:folder)    { create :file, :folder, id: 'folder', parent: root }
    let(:subfolder) { create :file, :folder, id: 'subfolder', parent: folder }
    let!(:file)     { create :file, id: 'file', parent: subfolder }
    let(:paths) do
      ['root',
       'root/folder',
       'root/folder/subfolder',
       'root/folder/subfolder/file']
    end

    it 'returns all the entries' do
      expect(method.map { |e| e[:name] }).to eq %w[root folder subfolder file]
    end

    it 'requires 3 recursions (lookups)' do
      file_collection
      expect_any_instance_of(VersionControl::Repository)
        .to receive(:lookup).exactly(3).times.and_call_original
      subject
    end

    it 'sorts results according to passed paths' do
      paths.reverse!
      expect(method.map { |e| e[:name] }).to eq %w[file subfolder folder root]
    end

    context 'when paths are complex' do
      let(:folder2) { create :file, :folder, id: 'folder2', parent: root }
      let(:sub2)    { create :file, :folder, id: 'subfolder2', parent: folder2 }
      let!(:file2)  { create :file, id: 'file2', parent: sub2 }

      let(:paths) do
        ['root',
         'root/folder',
         'root/folder/subfolder',
         'root/folder/subfolder/file',
         'root/folder2/subfolder2/file2',
         'root/folder2']
      end

      it 'returns all the entries' do
        expect(method.map { |e| e[:name] })
          .to eq %w[root folder subfolder file file2 folder2]
      end

      it 'requires 5 recursions (lookups)' do
        file_collection
        expect_any_instance_of(VersionControl::Repository)
          .to receive(:lookup).exactly(5).times.and_call_original
        subject
      end
    end

    context 'when some of the paths cannot be found' do
      before { paths << 'does not exist' }

      it 'returns all the entries' do
        expect(method[0..3].map { |e| e[:name] })
          .to eq %w[root folder subfolder file]
      end

      it 'sets the last entry to nil' do
        expect(method.last).to eq nil
      end
    end

    context 'when some of the paths are nil' do
      before { paths << nil }

      it 'returns all the entries' do
        expect(method[0..3].map { |e| e[:name] })
          .to eq %w[root folder subfolder file]
      end

      it 'sets the last entry to nil' do
        expect(method.last).to eq nil
      end
    end
  end

  describe '#group_paths_by_segment' do
    subject(:method) { file_collection.send :group_paths_by_segment, paths }
    let(:paths) do
      ['folder',
       'folder/subfolder',
       'folder/subfolder/file',
       'folder2/subfolder2/file2',
       'folder2']
    end

    it 'returns a hash grouped by initial path segment' do
      expect(method).to eq(
        'folder' => [nil, 'subfolder', 'subfolder/file'],
        'folder2' => ['subfolder2/file2', nil]
      )
    end
  end

  describe '#load_metadata(entry)' do
    subject(:method)  { file_collection.send :load_metadata, entry }
    let(:entry)       { file_collection.send(:find_entries_by_ids, [id]).first }

    context 'when entry is :blob type' do
      let(:id)      { file.id }
      let(:folder)  { create :file, :folder, parent: root }
      let!(:file)   { create :file, parent: folder }

      it do
        is_expected.to eq(
          name: file.name,
          mime_type: file.mime_type,
          version: file.version,
          modified_time: file.modified_time
        )
      end
    end

    context 'when entry is :tree type' do
      let(:id)      { folder.id }
      let!(:folder) { create :file, :folder, parent: root }

      it do
        is_expected.to eq(
          name: folder.name,
          mime_type: folder.mime_type,
          version: folder.version,
          modified_time: folder.modified_time
        )
      end
    end
  end

  describe '#metadata_entry_from_file_entry(entry)' do
    subject(:method) do
      file_collection.send :metadata_entry_from_file_entry, entry
    end
    let(:entry) { file_collection.send(:find_entries_by_ids, [id]).first }

    context 'when entry is :blob type' do
      let(:id)      { file.id }
      let(:folder)  { create :file, :folder, parent: root }
      let!(:file)   { create :file, parent: folder }

      it { is_expected.to eq entry }
    end

    context 'when entry is :tree type' do
      let(:id)      { folder.id }
      let!(:folder) { create :file, :folder, parent: root }

      it { is_expected.to include(name: '.self', type: :blob) }
    end
  end

  describe '#metadata_for(entry)' do
    subject(:method)  { file_collection.send :metadata_for, entry }
    let(:entry)       { file_collection.send(:find_entries_by_ids, [id]).first }
    let(:id)          { file.id }
    let(:folder)      { create :file, :folder, parent: root }
    let!(:file)       { create :file, parent: folder }

    it do
      is_expected.to eq(
        id: file.id,
        name: file.name,
        mime_type: file.mime_type,
        parent_id: folder.id,
        version: file.version,
        modified_time: file.modified_time,
        path: "#{root.id}/#{folder.id}/#{file.id}",
        git_oid: entry[:oid]
      )
    end

    context 'when entry is :tree type' do
      let(:id)          { folder.id }

      it do
        is_expected.to eq(
          id: folder.id,
          name: folder.name,
          mime_type: folder.mime_type,
          parent_id: root.id,
          version: folder.version,
          modified_time: folder.modified_time,
          path: "#{root.id}/#{folder.id}",
          git_oid: entry[:oid]
        )
      end
    end

    context 'when entry is nil' do
      let(:entry) { nil }
      it 'raises a invalid argument error' do
        expect { method }.to raise_error(
          Errno::EINVAL,
          'Invalid argument - Entry must be a Hash.'
        )
      end
    end
  end
end
