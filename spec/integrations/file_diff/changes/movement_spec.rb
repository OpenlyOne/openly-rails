# frozen_string_literal: true

RSpec.describe FileDiff::Changes::Movement, type: :model do
  subject             { revision }
  let(:change)        { file_diffs.find(diff.id).changes.first }
  let(:parent_change) { file_diffs.find(parent_diff.id).changes.first }
  let(:parent)        { create :file_resource, name: 'p-name' }
  let(:file)          { create :file_resource, name: 'c-name' }
  let(:revision)      { create :revision }
  let(:file_diffs)    { revision.file_diffs.reload }

  before { file.update(parent: parent) }

  let!(:diff) do
    create :file_diff,
           file_resource: file,
           current_snapshot_id: file.current_snapshot_id,
           previous_snapshot_id: file.current_snapshot_id_before_last_save,
           revision: revision
  end
  let!(:parent_diff) do
    create :file_diff,
           file_resource: parent,
           current_snapshot: parent.current_snapshot,
           previous_snapshot: nil,
           revision: revision
  end

  before { revision.assign_attributes(title: 'origin', is_published: true) }

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
