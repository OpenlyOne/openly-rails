# frozen_string_literal: true

RSpec.shared_examples 'being syncable' do
  describe '#fetch' do
    subject               { syncable }
    let(:sync_adapter)    { instance_double syncable.send(:sync_adapter_class) }
    let(:file_is_deleted) { false }

    before do
      allow(syncable).to receive(:sync_adapter).and_return sync_adapter
      allow(sync_adapter).to receive(:name).and_return 'name'
      allow(sync_adapter).to receive(:mime_type).and_return 'mime_type'
      allow(sync_adapter).to receive(:content_version).and_return 'version'
      allow(sync_adapter).to receive(:parent_id).and_return 'parent_id'
      allow(syncable).to receive(:thumbnail_from_sync_adapter)
      allow(sync_adapter).to receive(:deleted?).and_return false
    end

    after { syncable.fetch }

    it { expect(syncable).to receive(:name=).with('name') }
    it { expect(syncable).to receive(:mime_type=).with('mime_type') }
    it { expect(syncable).to receive(:content_version=).with('version') }
    it { expect(syncable).to receive(:external_parent_id=).with('parent_id') }
    it { expect(syncable).to receive(:thumbnail_from_sync_adapter) }
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

  describe '#pull_children' do
    before do
      allow(syncable)
        .to receive(:children_from_sync_adapter).and_return 'children'
    end
    after { syncable.pull_children }
    it    { expect(syncable).to receive(:children=).with('children') }
  end

  describe '#reload' do
    before  { allow(described_class).to receive(:find) }
    after   { syncable.reload }
    it      { expect(syncable).to receive(:reset_sync_adapter) }
  end

  describe '#find_by_or_initialize_and_pull(sync_adapter, attributes)' do
    subject(:method) do
      syncable.send :find_by_or_initialize_and_pull, 'adapter', x: 'y'
    end
    let(:file_in_db) { 'file-in-db' }

    before do
      allow(described_class)
        .to receive(:find_by).with(x: 'y').and_return file_in_db
    end

    it { is_expected.to eq 'file-in-db' }

    context 'when file does not exist in db' do
      let(:file_in_db)  { nil }
      let(:new_file)    { instance_double described_class }

      before do
        allow(described_class).to receive(:new).and_call_original
        allow(described_class)
          .to receive(:new)
          .with(x: 'y', sync_adapter: 'adapter')
          .and_return new_file
        allow(new_file).to receive(:pull)
      end

      it { is_expected.to eq new_file }
      it 'calls #pull on new file' do
        expect(new_file).to receive(:pull)
        subject
      end
    end
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

  describe '#thumbnail_from_sync_adapter' do
    subject(:set_thumbnail) { syncable.send(:thumbnail_from_sync_adapter) }
    let(:sync_adapter)  { instance_double syncable.send(:sync_adapter_class) }
    let(:has_thumbnail) { true }

    before do
      allow(syncable).to receive(:sync_adapter).and_return sync_adapter
      allow(sync_adapter).to receive(:thumbnail?).and_return has_thumbnail
    end

    it 'finds or initializes thumbnail by file resource' do
      stub      = class_double FileResource::Thumbnail
      thumbnail = instance_double FileResource::Thumbnail
      expect(FileResource::Thumbnail)
        .to receive(:create_with).with(raw_image: anything).and_return stub
      expect(stub)
        .to receive(:find_or_initialize_by_file_resource)
        .with(syncable)
        .and_return thumbnail
      expect(syncable).to receive(:thumbnail=).with(thumbnail)
      set_thumbnail
    end

    context 'when sync_adapter#thumbnail? is false' do
      let(:has_thumbnail) { false }
      it                  { is_expected.to be nil }
    end
  end
end
