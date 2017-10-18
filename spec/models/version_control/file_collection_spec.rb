# frozen_string_literal: true

RSpec.describe VersionControl::FileCollection, type: :model do
  subject(:file_collection) { build :vc_file_collection }

  it 'has a valid factory' do
    expect { subject }.not_to raise_error
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

  describe '#build' do
    subject(:method)      { file_collection.build arguments }
    let(:file_collection) { build :vc_file_collection }
    let(:arguments) do
      {
        name: 'file1',
        content: 'Content of the new file',
        revision_summary: 'Create new file: file1',
        revision_author: build_stubbed(:user)
      }
    end

    it { is_expected.to be_a VersionControl::File }

    it 'calls .new on VersionControl::File' do
      expect(VersionControl::File)
        .to receive(:new).with arguments.merge(collection: file_collection)
      method
    end

    context 'when no arguments are passed' do
      subject(:method) { file_collection.build }

      it { is_expected.to be_a VersionControl::File }

      it 'calls .new on VersionControl::File' do
        expect(VersionControl::File)
          .to receive(:new).with collection: file_collection
        method
      end
    end
  end

  describe '#create' do
    subject(:method)      { file_collection.create arguments }
    let(:file_collection) { build :vc_file_collection }
    let(:arguments) do
      {
        name: 'file1',
        content: 'Content of the new file',
        revision_summary: 'Create new file: file1',
        revision_author: build_stubbed(:user)
      }
    end

    it 'calls .create on VersionControl::File' do
      expect(VersionControl::File)
        .to receive(:create).with arguments.merge(collection: file_collection)
      method
    end

    it 'calls reload! on itself' do
      allow(VersionControl::File).to receive(:create)
      expect(file_collection).to receive(:reload!)
      method
    end
  end

  describe '#exists?' do
    subject(:method)  { file_collection.reload!.exists? name }
    let(:name)        { file.name }
    let!(:file)       { create :vc_file, collection: file_collection }
    it                { is_expected.to be true }
    it 'ignores case' do
      file_collection.reload!
      expect(file_collection).to exist file.name.upcase
      expect(file_collection).to exist file.name.downcase
    end

    context 'when file does not exist' do
      let(:name)  { "#{file.name}abc" }
      it          { is_expected.to be false }
    end
  end

  describe '#find' do
    subject(:method)  { file_collection.reload!.find name }
    let(:name)        { file.name }
    let!(:file)       { create :vc_file, collection: file_collection }

    it 'returns an instance of File' do
      is_expected.to be_a VersionControl::File
    end

    it 'marks file as persisted' do
      is_expected.to be_persisted
    end

    it 'ignores case' do
      file_collection.reload!
      expect(file_collection.find(file.name.upcase).oid).to eq file.oid
      expect(file_collection.find(file.name.downcase).oid).to eq file.oid
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

  describe '#preload_last_contribution' do
    subject(:method) { file_collection.preload_last_contribution }
    let(:file_collection) { create :vc_file_collection }
    let!(:files) { create_list :vc_file, 5, collection: file_collection }
    before { file_collection.reload! }

    it 'assigns @author on last_contributon' do
      method
      file_collection.each do |file|
        file_author = files.find { |f| f.name == file.name }.revision_author_was
        expect(file.last_contribution.instance_variable_get(:@author))
          .to eq(file_author)
      end
    end

    it 'returns itself for chaining' do
      is_expected.to be_a VersionControl::FileCollection
    end

    it 'does not cause a N+1 query' do
      Bullet.start_request
      method
      Bullet.perform_out_of_channel_notifications if Bullet.notification?
      Bullet.end_request
    end
  end

  describe '#reload!' do
    let(:author) { build(:user) }

    it 'returns itself for chaining' do
      expect(subject.reload!).to be_a VersionControl::FileCollection
    end

    it 'initializes VersionControl::File objects' do
      create :vc_file, collection: file_collection
      expect(subject.reload!.entries.first).to be_a VersionControl::File
    end

    it 'consists of files from last commit on master branch' do
      # Create 3 files
      3.times.with_index do |i|
        create(:vc_file,
               name: "file#{i}",
               content: "content#{i}",
               collection: file_collection)
      end

      # Confirm three files in collection
      3.times.with_index do |i|
        expect(
          subject.reload!.any? do |file|
            file.name == "file#{i}" && file.content == "content#{i}"
          end
        ).to be true
      end
    end

    it 'marks files as persisted' do
      create_list :vc_file, 5, collection: file_collection
      expect(subject.all?(&:persisted?)).to be true
    end

    context 'when no commit exists' do
      it { expect(subject.entries).to eq [] }
    end
  end
end
