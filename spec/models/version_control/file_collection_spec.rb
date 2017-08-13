# frozen_string_literal: true

RSpec.describe VersionControl::FileCollection, type: :model do
  subject(:file_collection) { build :vc_file_collection }

  it 'has a valid factory' do
    expect { subject }.not_to raise_error
  end

  describe 'delegations' do
    it 'delegates #lookup' do
      expect_any_instance_of(VersionControl::Repository).to receive :lookup
      subject.send :lookup, 'string'
    end
  end

  describe '.new(repository)' do
    context 'when repository is nil' do
      subject(:file_collection) { build :vc_file_collection, repository: nil }

      it 'raises an error' do
        expect { subject }.to raise_error(
          'VersionControl::FileCollection must initialized with a ' \
          'VersionControl::Repository instance'
        )
      end
    end

    it 'initializes files' do
      expect_any_instance_of(VersionControl::FileCollection).to receive :reload!
      subject
    end
  end

  describe '#create' do
    subject(:method)  { file_collection.create name, content, message, author }
    let(:author)      { build(:user) }
    let(:content)     { Faker::Lorem.paragraphs.join('\n\n') }
    let(:name)        { Faker::File.file_name('', nil, nil, '') }
    let(:message)     { Faker::Simpsons.quote }
    let(:repository)  { file_collection.instance_variable_get(:@repository) }

    it { is_expected.to be true }

    it 'writes the blob to the repository' do
      expect_any_instance_of(VersionControl::Repository)
        .to receive(:write)
        .with(content, :blob)
        .and_call_original
      method
    end

    it 'drop previously staged files (reset to last commit)' do
      # stage three files
      3.times.with_index do |i|
        blob_oid = repository.write("file content #{i}", :blob)
        repository.index.add path: "File#{i}", oid: blob_oid, mode: 0o100644
      end

      # run method
      method

      # Confirm that previous staged files are not included in commit
      tree = repository.branches['master'].target.tree
      expect(tree.count).to eq 1
      tree.each do |file|
        expect(file[:name]).not_to match(/File[123]/)
      end
    end

    it 'stages the new file' do
      method
      # Get the tree of the last commit
      tree = repository.branches['master'].target.tree

      # Confirm that file path is in tree
      expect(tree.any? { |file| file[:name] == name }).to be true

      # Confirm that blob content is what we submitted
      blob_oid = tree.find { |f| f[:name] == name }[:oid]
      expect(repository.lookup(blob_oid).content).to eq content
    end

    it 'calls commit on the repository' do
      expect_any_instance_of(VersionControl::Repository)
        .to receive(:commit)
        .with message, author
      method
    end

    it 'calls reload! on itself' do
      expect(file_collection).to receive :reload!
      method
    end

    context 'when commit fails' do
      before do
        allow_any_instance_of(VersionControl::Repository)
          .to receive(:commit)
          .and_return false
      end
      it { is_expected.to be false }
    end
  end

  describe '#find' do
    subject(:method)  { file_collection.find name }
    let(:name)        { file.name }
    let!(:file)       { create :vc_file, collection: file_collection }

    it 'returns an instance of File' do
      is_expected.to be_a VersionControl::File
    end

    it 'returns the right file' do
      found_file = method
      expect(found_file.name).to    eq file.name
      expect(found_file.oid).to     eq file.oid
      expect(found_file.content).to eq file.content
    end

    context 'when file with name does not exist' do
      let(:name)  { 'does-not-exist.doc' }
      it { expect { subject }.to raise_error ActiveRecord::RecordNotFound }
    end
  end

  describe '#reload!' do
    let(:author) { build(:user) }

    it 'returns itself for chaining' do
      expect(subject.reload!).to be_a VersionControl::FileCollection
    end

    it 'initializes VersionControl::File objects' do
      subject.create 'name', 'content', 'message', author
      expect(subject.entries.first).to be_a VersionControl::File
    end

    it 'consists of files from last commit on master branch' do
      # Create 3 files
      3.times.with_index do |i|
        subject.create "file#{i}", "content#{i}", 'message', author
      end

      # Confirm three files in collection
      3.times.with_index do |i|
        expect(
          subject.any? do |file|
            file.name == "file#{i}" && file.content == "content#{i}"
          end
        ).to be true
      end
    end

    context 'when no commit exists' do
      it { expect(subject.entries).to eq [] }
    end
  end
end
