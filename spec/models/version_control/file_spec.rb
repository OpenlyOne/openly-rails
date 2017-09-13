# frozen_string_literal: true

require 'models/shared_examples/having_dirty_tracked_attribute.rb'

RSpec.describe VersionControl::File, type: :model do
  subject(:file) { build :vc_file }

  it 'has a valid factory' do
    is_expected.to be_valid
  end

  describe 'delegations' do
    it 'delegates #repository' do
      expect_any_instance_of(VersionControl::FileCollection)
        .to receive :repository
      subject.send :repository
    end
  end

  describe 'validations' do
    context 'on :destroy' do
      it { is_expected.to validate_presence_of(:revision_author).on(:destroy) }
      it { is_expected.to validate_presence_of(:revision_summary).on(:destroy) }
    end

    context 'on :save' do
      it { is_expected.to validate_presence_of(:revision_author).on(:save) }
      it { is_expected.to validate_presence_of(:revision_summary).on(:save) }
      context 'when validating name' do
        it { is_expected.to validate_presence_of(:name).on(:save) }

        it 'identical names are invalid' do
          existing_file = create :vc_file, collection: file.collection
          file.name = existing_file.name
          expect(file).to be_invalid(:save)
        end

        it 'different cases of the same name are invalid' do
          existing_file = create :vc_file, collection: file.collection
          file.name = existing_file.name.upcase
          expect(file).to be_invalid(:save)
        end

        it 'identical names in different repositories are valid' do
          existing_file = create :vc_file
          file.name = existing_file.name
          expect(file).to be_valid(:save)
        end

        it 'forward-slash is invalid' do
          file.name = 'my/new/name'
          expect(file).to be_invalid(:save)
        end

        context 'when name has not changed' do
          before { file.save }
          it 'does not mark file as invalid' do
            file.content += 'abc'
            file.revision_summary = 'Update file content'
            file.revision_author  = file.revision_author_was
            expect(file).to be_valid(:save)
          end
        end
      end
    end
  end

  describe '.create' do
    subject(:method)      { VersionControl::File.create params }
    let(:repository)      { build :vc_repository }
    let(:file_collection) { build :vc_file_collection, repository: repository }
    let(:params) do
      {
        name: 'file1',
        content: 'My new file! :)',
        collection: file_collection,
        revision_summary: 'Create file1',
        revision_author: build_stubbed(:user)
      }
    end

    it { is_expected.to be_a VersionControl::File }

    it 'calls .new on VersionControl::File' do
      expect(VersionControl::File)
        .to receive(:new).with(params).and_call_original
      method
    end

    it 'calls #save on VersionControl::File instance' do
      expect_any_instance_of(VersionControl::File)
        .to receive(:save)
      method
    end
  end

  describe 'dirty tracking' do
    subject(:file)  { build :vc_file, revision_author: user, persisted: true }
    let(:user)      { build_stubbed :user }

    context 'when initializing new record' do
      subject(:file)  { build :vc_file }
      it              { is_expected.to be_changed }
    end

    context 'when initializing persisted record' do
      subject(:file)  { build :vc_file, persisted: true }
      it              { is_expected.not_to be_changed }
    end

    context 'when an attribute is changed' do
      before  { file.name = 'new value' }
      it      { is_expected.to be_changed }
    end

    it_should_behave_like 'having a dirty-tracked attribute', :name
    it_should_behave_like 'having a dirty-tracked attribute', :content
    it_should_behave_like 'having a dirty-tracked attribute', :revision_author
    it_should_behave_like 'having a dirty-tracked attribute', :revision_summary
  end

  describe '#content' do
    subject(:method)  { file.content }
    let(:file)        { create :vc_file }
    it                { is_expected.to eq file.content }

    context 'when file content is nil and oid is nil' do
      before do
        file.instance_variable_set :@content, nil
        file.instance_variable_set :@oid, nil
      end
      it { is_expected.to eq nil }
    end
  end

  describe '#destroy' do
    subject(:method)      { file.destroy }
    let!(:file)           { create :vc_file }
    let(:repository)      { file.repository }
    let(:file_collection) { file.collection }
    it                    { is_expected.to be_truthy }
    before do
      file.revision_author  = attributes_for(:vc_file)[:revision_author]
      file.revision_summary = attributes_for(:vc_file)[:revision_summary]
    end

    it 'returns the oid of the commit' do
      oid = Faker::Crypto.sha1
      allow(repository).to receive(:commit).and_return oid
      expect(method).to eq oid
    end

    it 'resets dirty tracking' do
      method
      expect(file.changes.keys).to eq %w[revision_author revision_summary]
      expect(file.previous_changes).not_to be_none
    end

    it 'resets revision author and revision summary' do
      method
      expect(file.revision_author).to be nil
      expect(file.revision_summary).to be nil
      expect(file.revision_author_was).not_to be nil
      expect(file.revision_summary_was).not_to be nil
    end

    it 'drop previously staged files (reset to last commit)' do
      # make sure we have a previous commit
      repository.commit 'initial commit', build_stubbed(:user)

      # stage three files
      3.times.with_index do |i|
        blob_oid = repository.write("file content #{i}", :blob)
        repository.index.add path: "File#{i}", oid: blob_oid, mode: 0o100644
      end

      # run method
      method

      # Confirm that previous staged files are not included in commit
      tree = repository.branches['master'].target.tree
      expect(tree.count).to eq 0
    end

    it 'removes a file from version control' do
      expect { method }.to(
        change { file_collection.reload!.count }.from(1).to(0)
      )
    end

    it 'sets persisted to false' do
      method
      expect(file).not_to be_persisted
    end

    context 'when file is not persisted' do
      before { file.instance_variable_set :@persisted, false }

      it 'prints out warning' do
        expect { method }.to raise_error ActiveRecord::Rollback
      end

      it 'does not commit the change' do
        expect(file.repository).not_to receive(:commit)
      end
    end

    context 'when file name is changed' do
      let!(:original_file_name) { file.name }
      let!(:new_file_name)      { 'new-file-name' }
      before do
        create :vc_file, collection: file_collection, name: new_file_name
        file.name = new_file_name
      end
      it 'removes the file by its original name' do
        method
        file_collection.reload!
        expect(file_collection).not_to exist original_file_name
        expect(file_collection).to exist new_file_name
      end
    end

    context 'when file is not in version control' do
      let(:file)  { create :vc_file }
      before do
        file.name = 'new-name'
        file.send :changes_applied
      end
      it { expect { method }.to raise_error Rugged::IndexError }
    end

    context 'when file is invalid' do
      before do
        allow(file).to receive(:valid?).with(:destroy).and_return false
      end
      it { is_expected.to be false }
    end

    context 'when .commit returns false' do
      before  { allow(repository).to receive(:commit).and_return false }
      it      { is_expected.to be false }

      it 'does not mark file as not-persisted' do
        method
        expect(file).to be_persisted
      end
    end
  end

  describe '#persisted?' do
    subject(:file) { VersionControl::File.new }
    it { is_expected.not_to be_persisted }

    context 'when persisted is set true on initialization' do
      subject(:file) { VersionControl::File.new persisted: true }
      it { is_expected.to be_persisted }
    end
  end

  describe '#save' do
    subject(:method)      { file.save }
    let(:file)            { build :vc_file }
    let(:file_collection) { file.collection }
    let(:repository)      { file.repository }
    it                    { is_expected.to be_truthy }

    it 'returns the oid of the commit' do
      oid = Faker::Crypto.sha1
      allow(repository).to receive(:commit).and_return oid
      expect(method).to eq oid
    end

    it 'marks file as persisted' do
      method
      expect(file).to be_persisted
    end

    it 'resets dirty tracking' do
      method
      expect(file.changes.keys).to eq %w[revision_author revision_summary]
      expect(file.previous_changes).not_to be_none
    end

    it 'resets revision author and revision summary' do
      method
      expect(file.revision_author).to be nil
      expect(file.revision_summary).to be nil
      expect(file.revision_author_was).not_to be nil
      expect(file.revision_summary_was).not_to be nil
    end

    it 'drop previously staged files (reset to last commit)' do
      # make sure we have a previous commit
      repository.commit 'initial commit', build_stubbed(:user)

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

    context 'when file is invalid' do
      before  { allow(file).to receive(:valid?).with(:save).and_return false }
      it      { is_expected.to be false }
    end

    context 'when .commit returns false' do
      before  { allow(repository).to receive(:commit).and_return false }
      it      { is_expected.to be false }

      it 'does not mark file as persisted' do
        method
        expect(file).not_to be_persisted
      end

      it 'does not reset dirty tracking' do
        method
        expect(file).to be_changed
        expect(file.previous_changes).to be_none
      end
    end

    context 'when file is new' do
      it 'adds a new file to version control' do
        expect { method }.to(
          change { file_collection.reload!.count }.from(0).to(1)
        )
      end

      it 'saves the name' do
        method
        expect(file_collection.reload!).to exist file.name
      end

      it 'saves the content' do
        method
        expect(file_collection.reload!.find(file.name).content)
          .to eq file.content
      end
    end

    context 'when file is persisted' do
      let!(:file) { create :vc_file }
      before do
        file.name     = 'README.txt'
        file.content  = 'Interesting things to read...!'
        file.revision_author  = attributes_for(:vc_file)[:revision_author]
        file.revision_summary = attributes_for(:vc_file)[:revision_summary]
      end

      it 'does not add a new file to version control' do
        expect { method }.not_to(change { file_collection.reload!.count })
      end

      it 'can update the name' do
        method
        expect(file_collection.reload!).to exist file.name
      end

      it 'can update the content' do
        method
        expect(file_collection.reload!.find(file.name).content)
          .to eq file.content
      end
    end
  end

  describe '#save!' do
    let(:file)        { build :vc_file }
    subject(:method)  { file.save! }

    it 'calls #save on VersionControl::File instance' do
      expect(file).to receive(:save).and_call_original
      method
    end

    context 'when #save is falsey' do
      before { allow(file).to receive(:save).and_return false }
      it 'raises ActiveRecord::RecordInvalid error' do
        expect { method }.to raise_error ActiveRecord::RecordInvalid
      end
    end
  end

  describe '#update' do
    subject(:method)  { file.update(params) }
    let(:file)        { create :vc_file }
    let(:collection)  { file.collection.reload! }
    let(:params) do
      {
        name: 'file1',
        content: 'My new file! :)',
        revision_summary: 'Create file1',
        revision_author: build_stubbed(:user)
      }
    end

    it 'sets content to new value' do
      method
      expect(collection.first.content).to eq params[:content]
    end

    it 'sets name to new value' do
      method
      expect(collection.first.name).to eq params[:name]
    end

    it 'calls #save on VersionControl::File instance' do
      expect(file).to receive(:save).and_call_original
      method
    end

    context 'when params are not passed' do
      subject(:method) { file.update }

      it 'calls #save on VersionControl::File instance' do
        expect(file).to receive(:save).and_call_original
        method
      end
    end
  end

  describe '#write_content_to_repository' do
    subject(:method)  { file.write_content_to_repository }
    let(:file)        { build :vc_file }

    it 'writes the blob to the repository' do
      expect_any_instance_of(VersionControl::Repository)
        .to receive(:write)
        .with(file.content, :blob)
        .and_call_original
      method
    end
  end
end
