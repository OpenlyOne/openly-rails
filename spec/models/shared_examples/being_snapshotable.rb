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
      subject                               { snapshotable }
      let(:saved_changes_to_core)           { false }
      let(:saved_changes_to_supplementals)  { false }
      let(:deleted)                         { false }

      before do
        allow(snapshotable)
          .to receive(:saved_changes_to_core_attributes?)
          .and_return saved_changes_to_core
        allow(snapshotable)
          .to receive(:saved_changes_to_supplemental_attributes?)
          .and_return saved_changes_to_supplementals
        allow(snapshotable).to receive(:deleted?).and_return deleted
      end

      after { snapshotable.save }

      it    { is_expected.not_to receive(:snapshot!) }

      context 'when core attributes have changed' do
        let(:saved_changes_to_core) { true }

        it { is_expected.to receive(:snapshot!) }

        context 'when file is deleted' do
          let(:deleted) { true }

          it { is_expected.not_to receive(:snapshot!) }
        end
      end

      context 'when supplemental attributes have changed' do
        let(:saved_changes_to_supplementals) { true }

        it { is_expected.to receive(:update_supplemental_snapshot_attributes) }

        context 'when file is deleted' do
          let(:deleted) { true }

          it do
            is_expected.not_to receive(:update_supplemental_snapshot_attributes)
          end
        end
      end
    end
  end

  describe '#core_attributes' do
    subject(:core_attributes) { snapshotable.send :core_attributes }

    it 'includes all core attributes' do
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
    it { is_expected.not_to include(:thumbnail_id) }
  end

  describe '#find_or_create_current_snapshot_by!(core_attrs, suppl_attrs)' do
    subject(:find_or_create) do
      snapshotable.send :find_or_create_current_snapshot_by!, core, supplemental
    end
    let(:core)          { { 'core' => 1 } }
    let(:supplemental)  { { 'supplemental' => 2 } }
    let(:snapshot)      { instance_double FileResource::Snapshot }

    before do
      snapshot_class = class_double FileResource::Snapshot
      allow(FileResource::Snapshot)
        .to receive(:create_with).with(supplemental).and_return snapshot_class
      allow(snapshot_class).to receive(:find_or_create_by!)
        .with(core).and_return snapshot
    end

    it 'sets current snapshot' do
      expect(snapshotable).to receive(:current_snapshot=).with(snapshot)
      find_or_create
    end
  end

  describe '#saved_changes_to_core_attributes?' do
    subject       { snapshotable.send :saved_changes_to_core_attributes? }
    let(:changes) { {} }

    before { allow(snapshotable).to receive(:saved_changes).and_return changes }

    it { is_expected.to be false }

    context 'when changes are only non-core attributes' do
      let(:changes) { { 'provider_id' => [0, 1], 'updated_at' => [0, 1] } }

      it { is_expected.to be false }
    end

    context 'when changes are core attributes' do
      let(:changes) { { 'name' => %w[a b], 'mime_type' => %w[c d] } }

      it { is_expected.to be true }
    end
  end

  describe '#saved_changes_to_supplemental_attributes?' do
    subject { snapshotable.send :saved_changes_to_supplemental_attributes? }
    let(:changes) { {} }

    before { allow(snapshotable).to receive(:saved_changes).and_return changes }

    it { is_expected.to be false }

    context 'when changes are only non-supplemental attributes' do
      let(:changes) { { 'name' => [0, 1], 'content_version' => [0, 1] } }

      it { is_expected.to be false }
    end

    context 'when changes are supplemental attributes' do
      let(:changes) { { 'thumbnail_id' => [nil, 1] } }

      it { is_expected.to be true }
    end
  end

  describe '#snapshot!' do
    subject(:capture_snapshot)    { snapshotable.send :snapshot! }
    let(:snapshot)                { instance_double FileResource::Snapshot }
    let(:core_attributes)         { { 'attr1': 'val1', 'attr2': 'val2' } }
    let(:supplemental_attributes) { { 'attr3': 'val3', 'attr4': 'val4' } }

    before do
      allow(snapshotable).to receive(:find_or_create_current_snapshot_by!)
      allow(snapshotable)
        .to receive(:core_snapshot_attributes)
        .and_return core_attributes
      allow(snapshotable)
        .to receive(:supplemental_snapshot_attributes)
        .and_return supplemental_attributes
      allow(snapshotable).to receive(:update_column)
      allow(snapshotable).to receive(:current_snapshot).and_return snapshot
      allow(snapshot).to receive(:id).and_return 123
    end

    after { capture_snapshot }

    it 'finds or creates a current snapshot by attributes' do
      expect(snapshotable)
        .to receive(:find_or_create_current_snapshot_by!)
        .with(core_attributes, supplemental_attributes)
    end

    it 'updates column to id of created snapshot' do
      expect(snapshotable)
        .to receive(:update_column).with('current_snapshot_id', 123)
    end
  end

  describe '#supplemental_attributes' do
    subject { snapshotable.send :supplemental_attributes }

    it 'includes all supplemental attributes' do
      is_expected.to eq(thumbnail_id: snapshotable.thumbnail_id)
    end
  end

  describe '#update_supplemental_snapshot_attributes' do
    let(:current_snapshot) { instance_double FileResource::Snapshot }
    let(:supplemental_attributes) { { a: 1, b: 2, c: 3 } }
    let(:supplemental_attributes_of_current_snapshot) { { c: 3, a: 2 } }

    before do
      allow(snapshotable)
        .to receive(:current_snapshot).and_return current_snapshot
      allow(snapshotable)
        .to receive(:supplemental_attributes)
        .and_return supplemental_attributes
      allow(snapshotable)
        .to receive(:supplemental_attributes_of_current_snapshot)
        .and_return supplemental_attributes_of_current_snapshot
    end

    after { snapshotable.send :update_supplemental_snapshot_attributes }

    it 'calls #update_columns on current snapshot' do
      expect(current_snapshot)
        .to receive(:update_columns)
        .with(a: 1, b: 2)
    end

    context 'when all supplemental attributes are up to date' do
      let(:supplemental_attributes_of_current_snapshot) do
        supplemental_attributes
      end

      it 'does not call #update_columns' do
        expect(current_snapshot).not_to receive(:update_columns)
      end
    end
  end
end
