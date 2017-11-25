# frozen_string_literal: true

RSpec.shared_examples 'being a file item' do
  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it {
      is_expected.to belong_to(:parent).class_name('FileItems::Folder')
      # .optional <- TODO: Upgrade shoulda-matchers gem and enable optional
    }
  end

  describe '#commit!' do
    let(:parent) { create :file_items_folder }
    before { subject.update(parent: parent) }
    before { subject.commit! }
    it 'marks file as committed' do
      expect(subject.reload).not_to be_added_since_last_commit
    end
    it 'sets version_at_last_commit' do
      expect(subject.reload.version_at_last_commit).not_to be nil
    end
    it 'sets modified_time_at_last_commit' do
      expect(subject.reload.modified_time_at_last_commit).not_to be nil
    end
    it 'sets parent_id_at_last_commit' do
      expect(subject.reload.parent_id_at_last_commit).not_to be nil
    end
  end

  describe '#external_link' do
    it { expect(subject).to respond_to :external_link }
  end

  describe '#icon' do
    it { expect(subject).to respond_to :icon }
  end

  describe '#mark_as_deleted(change)' do
    let(:file) { create subject.model_name.param_key.to_sym, :committed }
    let(:change_item) { build :google_drive_change }

    it 'marks the file as deleted_since_last_commit' do
      file.mark_as_deleted(change_item)
      expect(file.reload).to be_deleted_since_last_commit
    end

    it 'updates version' do
      file.mark_as_deleted(change_item)
      expect(file.reload.version).to eq change_item.file.version
    end

    it 'updates name' do
      file.mark_as_deleted(change_item)
      expect(file.reload.name).to eq change_item.file.name
    end

    context 'when file has not yet been committed' do
      let(:file) { create subject.model_name.param_key.to_sym }
      let(:project) { file.project }

      it 'deletes the file' do
        expect { file.mark_as_deleted(change_item) }.to(
          change { FileItems::Base.where(project: project).count }.by(-1)
        )
        expect(FileItems::Base)
          .not_to exist(project: project, id: file.id)
      end
    end

    context 'when change.file is nil' do
      let(:file) { create subject.model_name.param_key.to_sym, :committed }
      let(:change_item) { build :google_drive_change }
      before            { change_item.file = nil }

      it 'marks the file as deleted_since_last_commit' do
        file.mark_as_deleted(change_item)
        expect(file.reload).to be_deleted_since_last_commit
      end
    end
  end

  describe '#update_from_change(new_parent, change)' do
    let(:file) do
      create subject.model_name.param_key.to_sym,
             project: project,
             parent: new_parent
    end
    let(:change_item) { build :google_drive_change }
    let(:project)     { create :project }
    let(:new_parent)  { create :file_items_folder, project: project }

    it 'updates the file version' do
      file.update_from_change(new_parent, change_item)
      expect(file.reload.version).to eq change_item.file.version
    end

    it 'updates the file name' do
      file.update_from_change(new_parent, change_item)
      expect(file.reload.name).to eq change_item.file.name
    end

    it 'updates the file modified time' do
      file.update_from_change(new_parent, change_item)
      expect(file.reload.modified_time.to_i)
        .to eq change_item.file.modified_time.to_i
    end

    it 'does not move the file (by updating parent_id)' do
      expect { file.update_from_change(new_parent, change_item) }.not_to(
        change { file.reload.parent_id }
      )
    end

    context 'when new parent is different' do
      let(:current_parent)  { create :file_items_folder, project: project }
      before                { file.update(parent: current_parent) }

      it 'moves the file to the new folder (by updating parent_id)' do
        expect { file.update_from_change(new_parent, change_item) }.to(
          change { file.reload.parent_id }.to(new_parent.id)
        )
      end
    end

    context 'when new parent is nil' do
      let(:new_parent) { nil }

      it 'marks the file as deleted' do
        expect(file).to receive(:mark_as_deleted).with(change_item)
        file.update_from_change(new_parent, change_item)
      end
    end

    context 'when change.removed = true' do
      before { change_item.removed = true }

      it 'marks the file as deleted' do
        expect(file).to receive(:mark_as_deleted).with(change_item)
        file.update_from_change(new_parent, change_item)
      end
    end

    context 'when change.file.trashed = true' do
      before { change_item.file.trashed = true }

      it 'marks the file as deleted' do
        expect(file).to receive(:mark_as_deleted).with(change_item)
        file.update_from_change(new_parent, change_item)
      end
    end
  end

  describe '#added_since_last_commit?' do
    let!(:time) { Time.zone.now.utc }

    context 'when modified_time_at_last_commit is nil' do
      before  { subject.modified_time_at_last_commit = nil }
      it      { expect(subject).to be_added_since_last_commit }
    end

    context 'when modified_time_at_last_commit is not nil' do
      before  { subject.modified_time_at_last_commit = time }
      it      { expect(subject).not_to be_added_since_last_commit }
    end
  end

  describe '#deleted_since_last_commit?' do
    let!(:time) { Time.zone.now.utc }

    context 'when modified_time is nil' do
      before  { subject.modified_time = nil }
      it      { expect(subject).to be_deleted_since_last_commit }
    end
    context 'when modified_time is not nil' do
      before  { subject.modified_time = time }
      it      { expect(subject).not_to be_deleted_since_last_commit }
    end
  end

  describe '#modified_since_last_commit?' do
    before { subject.modified_time_at_last_commit = time }
    let!(:time) { Time.zone.now.utc }

    context 'when modified_time > modified_time_at_last_commit' do
      before  { subject.modified_time = time.tomorrow }
      it      { expect(subject).to be_modified_since_last_commit }
    end
    context 'when modified_time = modified_time_at_last_commit' do
      before  { subject.modified_time = time }
      it      { expect(subject).not_to be_modified_since_last_commit }
    end
    context 'when modified_time < modified_time_at_last_commit' do
      before  { subject.modified_time = time.yesterday }
      it      { expect(subject).not_to be_modified_since_last_commit }
    end
    context 'when modified time is nil' do
      before  { subject.modified_time = nil }
      it      { is_expected.not_to be_modified_since_last_commit }
    end
    context 'when modified time at last commit is nil' do
      before  { subject.modified_time_at_last_commit = nil }
      it      { is_expected.not_to be_modified_since_last_commit }
    end
    context 'when modified time and modified time at last commit are nil' do
      before  { subject.modified_time = nil }
      before  { subject.modified_time_at_last_commit = nil }
      it      { is_expected.not_to be_modified_since_last_commit }
    end
  end

  describe '#moved_since_last_commit?' do
    before { subject.parent_id = 1 }

    context 'when parent_id_at_last_commit != parent_id' do
      before  { subject.parent_id_at_last_commit = subject.parent_id + 1 }
      it      { expect(subject).to be_moved_since_last_commit }
    end
    context 'when parent_id_at_last_commit == parent_id' do
      before  { subject.parent_id_at_last_commit = subject.parent_id }
      it      { expect(subject).not_to be_moved_since_last_commit }
    end
  end
end
