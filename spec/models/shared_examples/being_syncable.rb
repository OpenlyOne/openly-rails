# frozen_string_literal: true

RSpec.shared_examples 'being syncable' do
  describe '#fetch' do
    subject               { syncable }
    let(:sync_adapter)    { instance_double syncable.send(:sync_adapter_class) }
    let(:file_is_deleted) { false }

    before do
      allow(syncable).to receive(:reset_sync_state)
      allow(syncable).to receive(:sync_adapter).and_return sync_adapter
      allow(sync_adapter).to receive(:name).and_return 'name'
      allow(sync_adapter).to receive(:mime_type).and_return 'mime_type'
      allow(sync_adapter).to receive(:content_version).and_return 'version'
      allow(sync_adapter).to receive(:parent_id).and_return 'parent_id'
      allow(sync_adapter).to receive(:deleted?).and_return false
    end

    after { syncable.fetch }

    it { expect(syncable).to receive(:reset_sync_state) }
    it { expect(syncable).to receive(:name=).with('name') }
    it { expect(syncable).to receive(:mime_type=).with('mime_type') }
    it { expect(syncable).to receive(:content_version=).with('version') }
    it { expect(syncable).to receive(:external_parent_id=).with('parent_id') }
    it { expect(syncable).to receive(:is_deleted=).with(false) }
  end

  describe '#pull' do
    subject(:pull) { syncable.pull }

    before do
      allow(syncable).to receive(:fetch)
      allow(syncable).to receive(:save)
    end

    after { pull }

    it { expect(syncable).to receive(:fetch) }
    it { expect(syncable).to receive(:save) }
  end

  describe '#external_parent_id=(parent_id)' do
    subject(:set_parent_id) { syncable.send(:external_parent_id=, parent_id) }
    let(:parent_id)         { 'id-of-parent' }
    let(:before_hook)       { nil }

    before { before_hook }
    before { set_parent_id }

    it { expect(syncable.parent).to eq nil }

    context 'when record with parent id exists' do
      let(:existing_record) { syncable.dup }
      let(:before_hook)     { existing_record.update(external_id: parent_id) }

      it { expect(syncable.parent).to eq existing_record }
    end
  end
end
