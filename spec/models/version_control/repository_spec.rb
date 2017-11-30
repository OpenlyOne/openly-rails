# frozen_string_literal: true

RSpec.describe VersionControl::Repository, type: :model do
  subject(:repository) { build :vc_repository }

  it 'has a valid factory' do
    expect { subject }.not_to raise_error
  end

  describe 'delegations' do
    methods = %i[bare? path workdir]

    methods.each do |method|
      it "delegates #{method}" do
        expect_any_instance_of(Rugged::Repository).to receive method
        subject.send method
      end
    end
  end

  describe '.create(path)' do
    let!(:repository) { build :vc_repository }
    let(:path)        { repository.path }

    it { is_expected.to be_a VersionControl::Repository }

    it 'creates a new repository at the path' do
      actual_path =
        Rails.root.join(`cd #{path}/objects; git rev-parse --git-dir`.strip)
      expect(actual_path.cleanpath).to eq Rails.root.join(path).cleanpath
    end

    it 'sets the repository to be non-bare' do
      expect(`cd #{path}; git rev-parse --is-bare-repository`).to eq "false\n"
    end

    it 'uses locking' do
      expect(VersionControl::Repository)
        .to receive(:lock).with(repository.workdir)
      VersionControl::Repository.create(repository.workdir)
    end

    context 'when repository already exists' do
      it 'raises an error' do
        expect { VersionControl::Repository.create(repository.workdir) }
          .to raise_error(Errno::EEXIST)
      end
    end
  end

  describe '.find(path)' do
    subject(:method) { VersionControl::Repository.find path }

    context 'when path is a git repository' do
      let(:repository)  { build :vc_repository }
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
    let(:repository1) { build :vc_repository }
    let(:repository2) { build :vc_repository }
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

  describe '#destroy' do
    subject(:method)  { repository.destroy }
    let(:repository)  { build :vc_repository }
    let(:path)        { repository.workdir }

    it 'deletes the files at path' do
      method
      expect(File).not_to exist path
    end

    it 'uses locking' do
      expect(VersionControl::Repository)
        .to receive(:lock).with(path)
      method
    end
  end

  describe '#lock' do
    subject(:method)  { repository.send :lock }
    let(:repository)  { build :vc_repository }
    let(:path)        { repository.workdir }

    it 'calls VersionControl::Repository.lock' do
      expect(VersionControl::Repository)
        .to receive(:lock).with(path)
      method
    end
  end
end
