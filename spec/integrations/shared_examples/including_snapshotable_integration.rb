# frozen_string_literal: true

RSpec.shared_examples 'including snapshotable integration' do
  let(:create)        { snapshotable.save }
  let(:from_database) { snapshotable.class.find(snapshotable.id) }

  describe 'create' do
    it { expect { create }.to change { FileResource::Snapshot.count }.by(1) }
  end

  describe 'update' do
    subject(:method)    { from_database.update(name: 'name', mime_type: 'doc') }
    before              { create }
    it { expect { method }.to change { FileResource::Snapshot.count }.by(1) }
  end

  describe 'is_deleted = true' do
    subject(:method)    { from_database.update(is_deleted: true) }
    before              { create }
    it { expect { method }.not_to(change { FileResource::Snapshot.count }) }
    it { expect { method }.not_to(change { FileResource.count }) }
  end

  describe 'when snapshot already exists' do
    let!(:original_name)        { snapshotable.name }
    let(:original_snapshot_id)  { snapshotable.snapshots.first.id }

    before do
      # create a snapshot with original attributes
      snapshotable.save

      # create a snapshot with new name
      snapshotable.update(name: 'new-name')

      # reset attributes to original ones
      snapshotable.name = original_name
    end

    it 'does not create a new snapshot' do
      expect { snapshotable.save }.not_to change(FileResource::Snapshot, :count)
    end

    it 'sets current snapshot ID to the existing snapshot' do
      expect { snapshotable.save }
        .to change(snapshotable, :current_snapshot_id).to(original_snapshot_id)
    end
  end
end
