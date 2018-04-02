# frozen_string_literal: true

RSpec.shared_examples 'being snapshotable' do
  describe 'associations' do
    it do
      is_expected.to have_many(:snapshots).class_name('FileResource::Snapshot')
    end
    it do
      is_expected.to belong_to(:current_snapshot)
        .class_name('FileResource::Snapshot')
        .validate(false).autosave(false).optional
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
      let(:deleted)                         { false }

      before { allow(snapshotable).to receive(:deleted?).and_return deleted }

      after { snapshotable.save }

      it    { is_expected.to receive(:snapshot!) }

      context 'when file is deleted' do
        let(:deleted) { true }

        it { is_expected.not_to receive(:snapshot!) }
      end
    end
  end

  describe '#snapshot!' do
    subject(:capture_snapshot)    { snapshotable.send :snapshot! }
    let(:snapshot)                { instance_double FileResource::Snapshot }

    before do
      allow(FileResource::Snapshot)
        .to receive(:for)
        .with(attribute: 'attr', file_resource_id: 'id')
        .and_return snapshot
      allow(snapshotable).to receive(:current_snapshot=).with(snapshot)
      allow(snapshotable).to receive(:current_snapshot).and_return(snapshot)
      allow(snapshotable).to receive(:attributes).and_return(attribute: 'attr')
      allow(snapshotable).to receive(:id).and_return 'id'
      allow(snapshot).to receive(:id).and_return 123
      allow(snapshotable).to receive(:update_column)
    end

    after { capture_snapshot }

    it 'calls for .for on FileResource::Snapshot and sets current_snapshot' do
      expect(FileResource::Snapshot)
        .to receive(:for)
        .with(attribute: 'attr', file_resource_id: 'id')
        .and_return(snapshot)
      expect(snapshotable).to receive(:current_snapshot=).with(snapshot)
    end

    it 'updates column to id of created snapshot' do
      expect(snapshotable)
        .to receive(:update_column).with('current_snapshot_id', 123)
    end
  end
end
