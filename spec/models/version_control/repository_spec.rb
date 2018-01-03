# frozen_string_literal: true

require 'models/shared_examples/version_control/repository_locking.rb'

RSpec.describe VersionControl::Repository, type: :model do
  subject(:repository) { build :repository }

  it 'has a valid factory' do
    expect { subject }.not_to raise_error
  end

  describe 'attributes' do
    it { should respond_to(:rugged_repository) }
  end

  describe 'delegations' do
    methods = %i[bare? path]

    methods.each do |method|
      it "delegates #{method}" do
        expect_any_instance_of(Rugged::Repository).to receive method
        subject.send method
      end
    end

    it 'delegates #lookup to rugged_repository' do
      expect_any_instance_of(Rugged::Repository).to receive :lookup
      subject.lookup 'some-object-id'
    end
  end

  describe '.create(path)' do
    subject(:method)  { VersionControl::Repository.create(path) }
    let(:directory)   { Rails.root.join(Settings.file_storage).to_s }
    let(:path)        { "#{directory}/my-new-repo" }

    it { is_expected.to be_a VersionControl::Repository }

    it 'creates a new repository at the path' do
      actual_path = Rails.root.join(
        `cd #{method.path}/objects; git rev-parse --git-dir`.strip
      )
      expect(actual_path.cleanpath).to eq Rails.root.join(method.path).cleanpath
    end

    it 'sets the repository to be non-bare' do
      method
      expect(`cd #{path}; git rev-parse --is-bare-repository`).to eq "false\n"
    end

    it_should_behave_like 'using repository locking' do
      let(:locker) { VersionControl::Repository }
    end

    context 'when repository already exists' do
      before { VersionControl::Repository.create(path) }

      it 'raises an error' do
        expect { method }.to raise_error(Errno::EEXIST)
      end
    end
  end

  describe '.find(path)' do
    subject(:method) { VersionControl::Repository.find path }

    context 'when path is a git repository' do
      let(:repository)  { build :repository }
      let(:workdir)     { repository.workdir }
      let(:path)        { repository.path }

      it { is_expected.to be_a VersionControl::Repository }
      it 'sets the correct repo' do
        expect(method.workdir).to eq workdir
        expect(method.path).to    eq path
      end
    end

    context 'when path is not a git repository' do
      let(:path)  { Rails.root.join(Settings.file_storage, 'not-a-repo').to_s }
      before      { FileUtils.mkdir_p path }
      it          { is_expected.to be nil }
    end

    context 'when path does not exist' do
      let(:path)  { Rails.root.join(Settings.file_storage, 'nothing').to_s }
      before      { FileUtils.rm_rf path }
      it          { is_expected.to be nil }
    end
  end

  describe '.lock(path)' do
    let(:repository1) { build :repository }
    let(:repository2) { build :repository }
    let(:path1)       { repository1.workdir }
    let(:path2)       { repository2.workdir }
    let(:thread1)     { double('Thread') }
    let(:thread2)     { double('Thread') }

    it 'locks the path to enforce execution of commands in sequence' do
      expect(thread1).to receive(:write).ordered
      expect(thread2).to receive(:write).ordered

      waiting_for_thread1 = true
      waiting_for_thread2 = true

      # Start thread 1
      Thread.start do
        waiting_for_thread1 = false
        VersionControl::Repository.lock(path1) do
          # Wait for Thread 2 to start
          sleep 0.1 while waiting_for_thread2
          # Write operation
          sleep 0.1
          thread1.write
        end
      end

      # Wait for thread 1 to start
      sleep 0.1 while waiting_for_thread1

      # Start Thread 2
      waiting_for_thread2 = false
      VersionControl::Repository.lock(path1) do
        thread2.write
      end
    end

    it 'creates a unique lock for every path' do
      waiting_for_thread1 = true
      waiting_for_thread2 = true

      # Start thread 1
      Thread.start do
        waiting_for_thread1 = false
        VersionControl::Repository.lock(path1) do
          # Wait for Thread 2 to start
          sleep 0.1 while waiting_for_thread2
          # Write operation
          sleep 5
        end
      end

      # Wait for thread 1 to start
      sleep 0.1 while waiting_for_thread1

      # Start Thread 2
      waiting_for_thread2 = false
      expect do
        VersionControl::Repository.lock(path2, wait: 0.1) {}
      end.not_to raise_error
    end
  end

  describe '#build_revision(tree_id = nil)' do
    subject(:method)  { repository.build_revision tree_id }
    let(:tree_id)     { nil }
    let!(:root)       { create :file, :root, repository: repository }
    let!(:folder)     { create :file, :folder, parent: root }
    let!(:file)       { create :file, parent: root }
    let!(:subfolder)  { create :file, :folder, parent: folder }
    let!(:subfile)    { create :file, parent: folder }

    it_should_behave_like 'using repository locking' do
      let(:locker) { repository }
    end

    it { is_expected.to be_an_instance_of VersionControl::Revisions::Drafted }

    it 'saves the stage / working directory' do
      expect(repository.stage).to receive(:save)
      subject
    end

    context 'when tree_id is passed' do
      let(:tree_id) { 'some-tree-id' }

      it { is_expected.to be_an_instance_of VersionControl::Revisions::Drafted }

      it 'does not save the stage / working directory' do
        expect(repository.stage).not_to receive(:save)
        subject
      end
    end
  end

  describe '#destroy' do
    subject(:method)  { repository.destroy }
    let(:repository)  { build :repository }
    let(:path)        { repository.workdir }

    it 'deletes the files at path' do
      method
      expect(File).not_to exist path
    end

    it_should_behave_like 'using repository locking' do
      let(:locker) { repository }
    end
  end

  describe '#lock' do
    subject(:method)  { repository.send :lock }
    let(:repository)  { build :repository }
    let(:path)        { repository.workdir }

    it 'calls VersionControl::Repository.lock' do
      expect(VersionControl::Repository).to receive(:lock).with(path)
      method
    end

    context 'when repository already has lock' do
      it 'does not call VersionControl::Repository.lock twice' do
        expect(VersionControl::Repository).to receive(:lock).with(path).once
        repository.send(:lock) { method }
      end
    end
  end

  describe '#revisions' do
    subject(:method)  { repository.revisions }
    it                { is_expected.to be_a VersionControl::RevisionCollection }
  end

  describe '#stage' do
    subject(:method)  { repository.stage }
    it                { is_expected.to be_a VersionControl::Revisions::Staged }
  end

  describe '#workdir' do
    subject(:method) { repository.workdir }

    it "is the cleanpath version of the rugged repository's workdir" do
      repo_path = repository.path
      workdir_path = ::File.expand_path('..', repo_path)
      is_expected.to eq Pathname(workdir_path).cleanpath.to_s
    end

    context 'when @rugged_repository is nil' do
      let(:repository) { VersionControl::Repository.new(nil) }
      it { is_expected.to be nil }
    end
  end
end
