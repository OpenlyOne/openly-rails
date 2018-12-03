# frozen_string_literal: true

RSpec.describe VCS::FileDiff::Changes::Movement, type: :model do
  subject             { commit }
  let(:change)        { file_diffs.find(diff.id).changes.first }
  let(:parent_change) { file_diffs.find(parent_diff.id).changes.first }
  let(:parent)        { create :vcs_file_in_branch, name: 'p-name' }
  let(:file)          { create :vcs_file_in_branch, name: 'c-name' }
  let(:commit)        { create :vcs_commit }
  let(:file_diffs)    { commit.file_diffs.reload }

  before { file.update(parent_in_branch: parent) }

  let!(:diff) do
    create :vcs_file_diff,
           current_snapshot_id: file.current_snapshot_id,
           previous_snapshot_id: file.current_snapshot_id_before_last_save,
           commit: commit
  end
  let!(:parent_diff) do
    create :vcs_file_diff,
           current_snapshot: parent.current_snapshot,
           previous_snapshot: nil,
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
        "You cannot move 'c-name' without adding its parent folder 'p-name'"
      ]
    end

    context 'when parent is selected' do
      before  { parent_change.select! }
      it      { is_expected.to be_valid }
    end

    context 'when parent is not being added' do
      let(:hook) do
        parent.update(name: 'new-name')
        parent_diff.update!(previous_snapshot: parent.current_snapshot)
      end
      it { is_expected.to be_valid }
    end
  end
end
