# frozen_string_literal: true

RSpec.describe VCS::Branch, type: :model do
  subject(:branch) { build_stubbed(:vcs_branch) }

  describe 'associations' do
    it { is_expected.to belong_to(:repository).dependent(false) }
    it { is_expected.to have_many(:files).dependent(:delete_all) }
    it do
      is_expected
        .to have_many(:versions_in_branch)
        .through(:files)
        .source(:current_version)
        .dependent(false)
    end
    it do
      is_expected
        .to have_many(:all_commits)
        .class_name('VCS::Commit')
        .dependent(:destroy)
    end
    it do
      is_expected
        .to have_many(:commits)
        .conditions(is_published: true)
        .dependent(false)
    end
  end

  describe 'delegations' do
    it { is_expected.to delegate_method(:root).to(:files) }
    it { is_expected.to delegate_method(:folders).to(:files) }
  end

  describe 'commits#create_draft_and_commit_files!' do
    subject(:method) do
      branch.commits.create_draft_and_commit_files!('author')
    end

    it 'calls VCS::Commit#create_draft_and_commit_files_for_project!' do
      expect(VCS::Commit)
        .to receive(:create_draft_and_commit_files_for_branch!)
        .with(branch, 'author')
      method
    end
  end

  describe '#create_remote_root_folder' do
    subject(:create_remote_root_folder) { branch.create_remote_root_folder }

    let(:root)                { nil }
    let(:built_root)          { instance_double VCS::FileInBranch }
    let(:repository)          { instance_double VCS::Repository }
    let(:sync_adapter_class)  { class_double Providers::GoogleDrive::FileSync }
    let(:mime_type_class)     { class_double Providers::GoogleDrive::MimeType }
    let(:remote_file) { instance_double Providers::GoogleDrive::FileSync }
    let(:files) do
      instance_double ActiveRecord::Associations::CollectionProxy
    end

    before do
      allow(branch).to receive(:root).and_return root
      allow(branch)
        .to receive(:sync_adapter_class).and_return sync_adapter_class
      allow(branch).to receive(:mime_type_class).and_return mime_type_class
      allow(sync_adapter_class).to receive(:create).and_return remote_file
      allow(mime_type_class).to receive(:folder).and_return 'folder-type'
      allow(branch).to receive(:files).and_return files
      allow(files).to receive(:build).and_return built_root
      allow(branch).to receive(:repository).and_return repository
      allow(repository)
        .to receive_message_chain(:files, :root)
        .and_return 'root-file-record'
      allow(built_root).to receive(:pull)

      allow(branch).to receive(:id).and_return 'id-of-branch'
      allow(remote_file).to receive(:id).and_return 'root-folder-id'

      create_remote_root_folder
    end

    it 'calls #create on sync adapter class' do
      expect(sync_adapter_class)
        .to have_received(:create)
        .with(
          name: 'Branch #id-of-branch',
          parent_id: 'root',
          mime_type: 'folder-type'
        )
    end

    it 'creates the staged root locally' do
      expect(files)
        .to have_received(:build)
        .with(
          remote_file_id: 'root-folder-id',
          file: 'root-file-record',
          is_root: true
        )
      expect(built_root).to have_received(:pull)
    end

    context 'when root already exists' do
      let(:root) { instance_double VCS::FileInBranch }

      it { is_expected.to be false }

      it { expect(sync_adapter_class).not_to have_received(:create) }
      it { expect(files).not_to have_received(:build) }
    end
  end

  describe '#restore_commit' do
    subject(:restore_commit) do
      branch.restore_commit('commit', author: 'author')
    end

    before { allow(VCS::Operations::CommitRestore).to receive(:restore) }

    it 'calls #restore on CommitRestore operation' do
      restore_commit

      expect(VCS::Operations::CommitRestore)
        .to have_received(:restore)
        .with(
          commit: 'commit',
          target_branch: branch,
          author: 'author'
        )
    end
  end
end
