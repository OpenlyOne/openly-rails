# frozen_string_literal: true

RSpec.describe VCS::FileDiff::Changes::Deletion, type: :model do
  subject             { commit }
  let(:change)        { file_diffs.find(diff.id).changes.first }
  let(:child1_change) { file_diffs.find(child1_diff.id).changes.first }
  let(:child2_change) { file_diffs.find(child2_diff.id).changes.first }
  let(:file)          { create :vcs_file_in_branch, name: 'c-name' }
  let(:child1) do
    create :vcs_file_in_branch, name: 'child1', parent_in_branch: file
  end
  let(:child2) do
    create :vcs_file_in_branch, name: 'child2', parent_in_branch: file
  end
  let(:child_changes) { [child1_change, child2_change] }
  let(:commit)        { create :vcs_commit }
  let(:file_diffs)    { commit.file_diffs.reload }

  let!(:diff) do
    create :vcs_file_diff,
           current_version: nil,
           previous_version: file.current_version,
           commit: commit
  end

  before { commit.assign_attributes(title: 'origin', is_published: true) }

  describe 'validation: must_not_unselect_deletion_of_children' do
    let!(:child1_diff) do
      create :vcs_file_diff,
             current_version: nil,
             previous_version: child1.current_version,
             commit: commit
    end
    let!(:child2_diff) do
      create :vcs_file_diff,
             current_version: nil,
             previous_version: child2.current_version,
             commit: commit
    end
    let(:hook)  { nil }
    before      { hook }
    before      { child_changes.each(&:unselect!) }

    it 'adds an error' do
      is_expected.to be_invalid
      expect(change.errors.full_messages).to eq [
        "You cannot delete 'c-name' without deleting its contents: "\
        'child1 and child2'
      ]
    end

    context 'when children are selected' do
      before  { child_changes.each(&:select!) }
      it      { is_expected.to be_valid }
    end

    context 'when children are not being deleted' do
      let(:hook) do
        child1.update(name: 'new-name')
        child2.update(name: 'new-name')
        child1_diff.update!(current_version: child1.current_version)
        child2_diff.update!(current_version: child2.current_version)
      end
      it { is_expected.to be_valid }
    end
  end

  describe 'validation: must_not_unselect_movement_of_children' do
    let(:new_parent) { create :vcs_file_in_branch }

    before do
      child1.update!(parent_in_branch: new_parent)
      child2.update!(parent_in_branch: new_parent)
    end

    let!(:child1_diff) do
      create :vcs_file_diff,
             current_version: child1.current_version,
             previous_version_id: child1.current_version_id_before_last_save,
             commit: commit
    end
    let!(:child2_diff) do
      create :vcs_file_diff,
             current_version: child2.current_version,
             previous_version_id: child2.current_version_id_before_last_save,
             commit: commit
    end
    let(:hook)  { nil }
    before      { hook }
    before      { child_changes.each(&:unselect!) }

    it 'adds an error' do
      is_expected.to be_invalid
      expect(change.errors.full_messages).to eq [
        "You cannot delete 'c-name' without moving its contents: "\
        'child1 and child2'
      ]
    end

    context 'when children are selected' do
      before  { child_changes.each(&:select!) }
      it      { is_expected.to be_valid }
    end

    context 'when children are not being moved' do
      let(:hook) do
        child1.update(name: 'new-name', parent_in_branch: file)
        child2.update(name: 'new-name', parent_in_branch: file)
        child1_diff.update!(current_version: child1.current_version)
        child2_diff.update!(current_version: child2.current_version)
      end
      it { is_expected.to be_valid }
    end
  end
end
