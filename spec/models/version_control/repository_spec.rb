# frozen_string_literal: true

RSpec.describe VersionControl::Repository, type: :model do
  subject(:repository) { build :vc_repository }

  it 'has a valid factory' do
    expect { subject }.not_to raise_error
  end

  describe 'delegations' do
    methods = %i[bare? branches index path]

    methods.each do |method|
      it "delegates #{method}" do
        expect_any_instance_of(Rugged::Repository).to receive method
        subject.send method
      end
    end

    it 'delegates #lookup' do
      expect_any_instance_of(Rugged::Repository).to receive :lookup
      subject.send :lookup, 'string'
    end

    it 'delegates #write' do
      expect_any_instance_of(Rugged::Repository).to receive :write
      subject.send :write, 'string', :blob
    end
  end

  describe '.create(path)' do
    subject(:method)  { VersionControl::Repository.create path, :bare }
    let(:path)        { Rails.root.join('spec/tmp/new-repo.git').to_s }

    it { is_expected.to be_a VersionControl::Repository }

    it 'creates a new repository at the path' do
      method
      expect(`cd #{path}/objects; git rev-parse --git-dir`).to eq "#{path}\n"
    end

    it 'sets the repository to be bare' do
      method
      expect(`cd #{path}; git rev-parse --is-bare-repository`).to eq "true\n"
    end
  end

  describe '.find(path)' do
    subject(:method) { VersionControl::Repository.find path }

    context 'when path is a git repository' do
      let(:path) { Rails.root.join('spec', 'tmp', 'my-awesome-repo.git/').to_s }
      before { build :vc_repository, path: path }

      it { is_expected.to be_a VersionControl::Repository }
      it 'sets the correct repo' do
        expect(method.path).to eq path
      end
    end

    context 'when path is not a git repository' do
      let(:path)  { Rails.root.join('spec/tmp/not-a-repo').to_s }
      before      { FileUtils.mkdir_p path }
      it          { is_expected.to be nil }
    end

    context 'when path does not exist' do
      let(:path)  { Rails.root.join('spec/tmp/nothing-here').to_s }
      before      { FileUtils.rm_rf path }
      it          { is_expected.to be nil }
    end
  end

  describe '#rename(new_path)' do
    subject(:method)  { repository.rename new_path }
    let(:repository)  { build :vc_repository }
    let!(:old_path)   { repository.path }
    let!(:new_path)   { repository.path[0..-2] + '.new.git/' }

    it 'moves the repository to the new path' do
      method
      expect(VersionControl::Repository.find(old_path)).to be nil
      expect(VersionControl::Repository.find(new_path)).not_to be nil
    end

    it 'updates its reference to rugged_repository' do
      expect(Rugged::Repository).to receive(:new).and_call_original
      method
      expect(repository.path).to eq new_path
    end

    context 'when repository is not bare' do
      let(:repository) { build :vc_repository, bare: nil }
      it 'raises an error' do
        expect { method }.to raise_error 'Cannot rename non-bare repositories'
      end
    end
  end

  describe '#commit' do
    subject(:method)  { repository.commit message, author }
    let(:author)      { build :user }
    let(:message)     { 'Hey there! My new commit!' }
    let(:path)        { repository.path }
    let(:commit_oid)  { repository.branches['master'].target.oid }
    let(:commit_content) do
      `cd #{path}; git cat-file -p "#{commit_oid}"`
    end

    it { is_expected.to be_truthy }

    it 'creates a new commit' do
      method
      expect(`cd #{path}; git cat-file -t "#{commit_oid}"`).to eq "commit\n"
    end

    it 'saves the author' do
      method
      # clean crud characters from author name
      # See: https://stackoverflow.com/a/26219423/6451879
      clean_author_name =
        author.name
              .gsub(/[\.,:;<>"\\']+$/, '') # remove trailing crud
              .gsub(/^[\.,:;<>"\\']+/, '') # remove leading crud
      expect(commit_content).to include clean_author_name
      expect(commit_content).to include author.username
    end

    it 'saves the message' do
      method
      expect(commit_content).to include message
    end

    it 'saves the current index/stage' do
      # stage three files
      3.times.with_index do |i|
        blob_oid = repository.write("file content #{i}", :blob)
        repository.index.add path: "File#{i}", oid: blob_oid, mode: 0o100644
      end

      # run the method
      method
      tree = repository.branches['master'].target.tree

      # confirm results
      expect(tree.count).to eq 3
      expect(tree.map { |file| file[:name] }).to eq %w[File0 File1 File2]
    end

    it 'updates the master ref' do
      # do a first commit, so that master is not empty
      repository.commit message, author

      oid_ref_before_commit = repository.branches['master'].target.oid
      repository.commit message, author
      oid_ref_after_commit = repository.branches['master'].target.oid

      expect(oid_ref_after_commit).not_to eq oid_ref_before_commit
    end

    context 'when commit fails' do
      before { allow(Rugged::Commit).to receive(:create).and_raise 'error' }
      it { is_expected.to be false }
    end
  end

  describe '#reset_index!' do
    let(:author)          { build(:user) }
    let(:file_collection) { VersionControl::FileCollection.new repository }
    before do
      # create a commit
      create :vc_file, collection: file_collection
    end

    it 'sets stage to last commit on master' do
      # reset the index
      repository.reset_index!

      tree_of_last_commit = repository.branches['master'].target.tree
      # Confirm that each indexed file is also part of the tree of the commit
      expect(repository.index.count).to eq tree_of_last_commit.count
      repository.index.each do |indexed_file|
        expect(
          tree_of_last_commit.any? do |committed_file|
            committed_file[:name] == indexed_file[:path] &&
            committed_file[:oid]  == indexed_file[:oid]
          end
        ).to be true
      end
    end

    it 'removes currently staged files' do
      # stage 3 files
      3.times.with_index do |i|
        blob_oid = repository.write("file content #{i}", :blob)
        repository.index.add path: "File#{i}", oid: blob_oid, mode: 0o100644
      end

      # reset the index
      repository.reset_index!

      expect(repository.index.count).to eq 1
      repository.index.each do |file|
        expect(file[:name]).not_to match(/File[123]/)
      end
    end
  end
end
