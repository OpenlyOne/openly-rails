# frozen_string_literal: true

RSpec.shared_examples 'including snapshotable integration' do
  describe 'callbacks' do
    let(:creation)        { snapshotable.save }
    let(:from_database) { snapshotable.class.find(snapshotable.id) }

    describe 'creation' do
      it do
        expect { creation }.to change { FileResource::Snapshot.count }.by(1)
      end
    end

    describe 'update' do
      subject(:method)  { from_database.update(name: 'name', mime_type: 'doc') }
      before            { creation }
      it { expect { method }.to change { FileResource::Snapshot.count }.by(1) }
    end

    describe 'is_deleted = true' do
      subject(:method)    { from_database.update(is_deleted: true) }
      before              { creation }
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
        expect { snapshotable.save }
          .not_to change(FileResource::Snapshot, :count)
      end

      it 'sets current snapshot ID to the existing snapshot' do
        expect { snapshotable.save }
          .to change(snapshotable, :current_snapshot_id)
          .to(original_snapshot_id)
      end

      context 'when supplemental attributes change' do
        let(:thumbnail) { create :file_resource_thumbnail }
        let(:snapshot)  { FileResource::Snapshot.order(:created_at).first }
        before          { snapshotable.thumbnail = thumbnail }

        it 'updates thumbnail on the snapshot' do
          expect { snapshotable.save }
            .to change { snapshot.reload.thumbnail_id }.from(nil)
        end
      end
    end
  end

  describe 'validation: current snapshot must belong to snapshotable' do
    let(:other_snapshot)  { create :file_resource_snapshot }
    before                { snapshotable.current_snapshot = other_snapshot }

    it 'adds error: must belong to snapshotable' do
      expect(snapshotable).to be_invalid
      expect(snapshotable.errors[:current_snapshot])
        .to contain_exactly "must belong to this #{snapshotable_model_name}"
    end
  end
end
