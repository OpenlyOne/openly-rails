# frozen_string_literal: true

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
    context 'on :create' do
      it { is_expected.to validate_presence_of(:revision_author).on(:create) }
      it { is_expected.to validate_presence_of(:revision_summary).on(:create) }
      context 'when validating name' do
        it { is_expected.to validate_presence_of(:name).on(:create) }

        it 'identical names are invalid' do
          existing_file = create :vc_file, collection: file.collection
          file.name = existing_file.name
          expect(file).to be_invalid(:create)
        end

        it 'different cases of the same name are invalid' do
          existing_file = create :vc_file, collection: file.collection
          file.name = existing_file.name.upcase
          expect(file).to be_invalid(:create)
        end

        it 'identical names in different repositories are valid' do
          existing_file = create :vc_file
          file.name = existing_file.name
          expect(file).to be_valid(:create)
        end

        it 'forward-slash is invalid' do
          file.name = 'my/new/name'
          expect(file).to be_invalid(:create)
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
    it { is_expected.to be_persisted }

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

    it 'adds a new file to version control' do
      expect { method }.to(
        change { file_collection.reload!.count }.from(0).to(1)
      )
    end

    it 'saves the name' do
      method
      expect(file_collection.reload!).to exist params[:name]
    end

    it 'saves the content' do
      method
      expect(file_collection.reload!.find(params[:name]).content)
        .to eq params[:content]
    end

    it 'resets revision author and revision summary' do
      file = method
      expect(file.revision_author).to be nil
      expect(file.revision_summary).to be nil
    end

    context 'when file is invalid' do
      before do
        allow_any_instance_of(VersionControl::File)
          .to receive(:valid?)
          .and_return false
      end
      it { is_expected.to be false }
    end
  end

  describe '#content' do
    subject(:method)  { file.content }
    let(:file)        { create :vc_file }
    it                { is_expected.to eq file.content }
  end

  describe '#persisted?' do
    subject(:file) { VersionControl::File.new }
    it { is_expected.not_to be_persisted }

    context 'when persisted is set true on initialization' do
      subject(:file) { VersionControl::File.new persisted: true }
      it { is_expected.to be_persisted }
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
