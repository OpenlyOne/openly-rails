# frozen_string_literal: true

RSpec.describe VCS::FileDiff::Changes::Addition, type: :model do
  subject                 { commit }
  let(:change)            { file_diffs.find(diff.id).changes.first }
  let(:parent_change)     { file_diffs.find(parent_diff.id).changes.first }
  let(:parent_in_branch)  { create :vcs_file_in_branch, name: 'p-name' }
  let(:file_in_branch) do
    create :vcs_file_in_branch,
           name: 'c-name', parent_in_branch: parent_in_branch
  end
  let(:commit)      { create :vcs_commit }
  let(:file_diffs)  { commit.file_diffs.reload }
  let!(:diff) do
    create :vcs_file_diff,
           current_version: file_in_branch.current_version,
           previous_version: nil,
           commit: commit
  end
  let!(:parent_diff) do
    create :vcs_file_diff,
           current_version: parent_in_branch.current_version,
           previous_version: nil,
           commit: commit
  end

  before { commit.assign_attributes(title: 'origin', is_published: true) }

  describe 'validation: must_not_unselect_addition_of_parent' do
    let(:hook)  { nil }
    before      { hook }
    before      { parent_change.unselect! }

    it 'adds an error' do
      is_expected.to be_invalid
      expect(change.errors.full_messages).to eq [
        "You cannot add 'c-name' without adding its parent folder 'p-name'"
      ]
    end

    context 'when parent is selected' do
      before  { parent_change.select! }
      it      { is_expected.to be_valid }
    end

    context 'when parent is not being added' do
      let(:hook) do
        parent_in_branch.update(name: 'new-name')
        parent_diff.update!(
          previous_version: parent_in_branch.current_version
        )
      end
      it { is_expected.to be_valid }
    end
  end
end
