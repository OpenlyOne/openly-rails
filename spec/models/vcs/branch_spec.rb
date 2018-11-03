# frozen_string_literal: true

RSpec.describe VCS::Branch, type: :model do
  subject(:branch) { build_stubbed(:vcs_branch) }

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
