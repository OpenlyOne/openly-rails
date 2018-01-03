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
end
