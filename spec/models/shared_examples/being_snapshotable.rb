# frozen_string_literal: true

RSpec.shared_examples 'being snapshotable' do
  describe 'associations' do
    it do
      is_expected.to have_many(:snapshots).class_name('FileResource::Snapshot')
    end
    it do
      is_expected.to belong_to(:current_snapshot)
        .class_name('FileResource::Snapshot').validate(false).autosave(false)
    end
  end

  describe 'callbacks' do
    before do
      allow(snapshotable).to receive(:clear_snapshot)
      allow(snapshotable).to receive(:snapshot!)
    end

    describe 'before_save' do
      subject       { snapshotable }
      let(:deleted) { false }

      before  { allow(snapshotable).to receive(:deleted?).and_return deleted }
      after   { snapshotable.save }

      it      { is_expected.not_to receive(:clear_snapshot) }

      context 'when file is deleted' do
        let(:deleted) { true }

        it { is_expected.to receive(:clear_snapshot) }
      end
    end

    describe 'after_save' do
      subject             { snapshotable }
      let(:saved_changes) { false }
      let(:deleted)       { false }

      before do
        allow(snapshotable)
          .to receive(:saved_changes_to_metadata?).and_return saved_changes
        allow(snapshotable).to receive(:deleted?).and_return deleted
      end

      after   { snapshotable.save }

      it      { is_expected.not_to receive(:snapshot!) }

      context 'when metadata has changed' do
        let(:saved_changes) { true }

        it { is_expected.to receive(:snapshot!) }

        context 'when file is deleted' do
          let(:deleted) { true }

          it { is_expected.not_to receive(:snapshot!) }
        end
      end
    end
  end

  describe 'callback: after_save' do
    subject { snapshotable }
    after   { snapshotable.save }
    it      { is_expected.to receive(:snapshot!) }
  end

  describe '#metadata' do
    subject(:metadata) { snapshotable.send :metadata }

    it 'includes all metadata' do
      is_expected.to include(
        name: snapshotable.name,
        external_id: snapshotable.external_id,
        mime_type: snapshotable.mime_type,
        content_version: snapshotable.content_version,
        parent_id: snapshotable.parent_id
      )
    end

    it { is_expected.not_to include(:id) }
    it { is_expected.not_to include(:provider_id) }
    it { is_expected.not_to include(:updated_at) }
    it { is_expected.not_to include(:created_at) }
  end

  describe '#find_or_create_current_snapshot_by!(attributes)' do
    subject(:find_or_create) do
      snapshotable.send :find_or_create_current_snapshot_by!, snapshot_attr
    end
    let(:snapshot_attr) { attributes.merge(file_resource_id: snapshotable.id) }
    let(:attributes) do
      { name: 'name', content_version: '15', mime_type: 'doc',
        external_id: 'abc', parent_id: nil }
    end
    let(:new_snapshot)  { FileResource::Snapshot.last }
    let(:before_hook)   { snapshotable.save }

    before { before_hook }

    it 'creates a new snapshot' do
      expect { find_or_create }.to change(FileResource::Snapshot, :count).by(1)
    end

    it 'creates snapshot with correct attributes' do
      find_or_create
      expect(new_snapshot.attributes).to include(
        'file_resource_id' => snapshotable.id,
        'name' => 'name',
        'external_id' => 'abc',
        'mime_type' => 'doc',
        'content_version' => '15',
        'parent_id' => nil
      )
    end

    it 'updates column to id of created snapshot' do
      find_or_create
      expect(snapshotable.current_snapshot_id).to eq new_snapshot.id
    end

    context 'when snapshot already exists' do
      before do
        snapshotable.assign_attributes(attributes)
        snapshotable.send :snapshot!
      end

      it 'does not create a new snapshot' do
        expect { find_or_create }.not_to change(FileResource::Snapshot, :count)
      end

      it 'updates column to id of existing snapshot' do
        find_or_create
        expect(snapshotable.current_snapshot_id).to eq new_snapshot.id
      end
    end

    context 'when snapshotable is a new record' do
      let(:before_hook) { nil }

      it 'does not create a new snapshot' do
        expect { find_or_create }.to raise_error ActiveRecord::RecordInvalid
      end
    end

    context 'when snapshotable is destroyed' do
      let(:before_hook) { snapshotable.save && snapshotable.destroy }

      it 'does not create a new snapshot' do
        expect { find_or_create }.to raise_error ActiveRecord::RecordInvalid
      end
    end
  end

  describe '#saved_changes_to_metadata?' do
    subject(:saved_changes) { snapshotable.send :saved_changes_to_metadata? }
    let(:changes) { {} }

    before { allow(snapshotable).to receive(:saved_changes).and_return changes }

    it { is_expected.to be false }

    context 'when changes are only non-metadata attributes' do
      let(:changes) { { 'provider_id' => [0, 1], 'updated_at' => [0, 1] } }

      it { is_expected.to be false }
    end

    context 'when changes are metadata attributes' do
      let(:changes) { { 'name' => %w[a b], 'mime_type' => %w[c d] } }

      it { is_expected.to be true }
    end
  end

  describe '#snapshot!' do
    subject(:capture_snapshot) { snapshotable.send :snapshot! }
    let(:snapshot)    { instance_double FileResource::Snapshot }
    let(:attributes)  { { 'attribute1': 'value1', 'attribute2': 'value2' } }

    before do
      allow(snapshotable).to receive(:find_or_create_current_snapshot_by!)
      allow(snapshotable).to receive(:snapshot_attributes).and_return attributes
      allow(snapshotable).to receive(:update_column)
      allow(snapshotable).to receive(:current_snapshot).and_return snapshot
      allow(snapshot).to receive(:id).and_return 123
    end

    after { capture_snapshot }

    it 'finds or creates a current snapshot by attributes' do
      expect(snapshotable)
        .to receive(:find_or_create_current_snapshot_by!)
        .with('attribute1': 'value1', 'attribute2': 'value2')
    end

    it 'updates column to id of created snapshot' do
      expect(snapshotable)
        .to receive(:update_column).with('current_snapshot_id', 123)
    end
  end
end
