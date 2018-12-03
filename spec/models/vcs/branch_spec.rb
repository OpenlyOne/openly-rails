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
end
