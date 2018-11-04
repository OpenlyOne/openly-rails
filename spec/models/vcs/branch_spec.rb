# frozen_string_literal: true

RSpec.describe VCS::Branch, type: :model do
  subject(:branch) { build_stubbed(:vcs_branch) }

  describe 'associations' do
    it { is_expected.to belong_to(:repository).dependent(false) }
    it { is_expected.to have_many(:staged_files).dependent(:delete_all) }
    it do
      is_expected
        .to have_many(:staged_file_snapshots)
        .through(:staged_files)
        .source(:current_snapshot)
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
    it { is_expected.to delegate_method(:root).to(:staged_files) }
    it do
      is_expected
        .to delegate_method(:folders).to(:staged_files).with_prefix('staged')
    end
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
end
