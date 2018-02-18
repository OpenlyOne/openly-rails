# frozen_string_literal: true

RSpec.shared_examples 'including syncable integration', :vcr do
  let(:file_sync) do
    file_sync_class.create(
      name: 'Test File',
      parent_id: parent_id,
      mime_type: mime_type
    )
  end

  describe '#fetch' do
    subject(:fetch)         { syncable.fetch }
    let(:external_id)       { file_sync.id }
    let(:before_fetch_hook) { nil }

    before { before_fetch_hook }
    before { fetch }

    it { expect(syncable.name).to eq 'Test File' }
    it { expect(syncable.mime_type).to eq mime_type }
    it { expect(syncable.content_version).to eq '1' }
    it { expect(syncable.parent).to eq nil }
    it { expect(syncable).not_to be_deleted }

    context 'when file is trashed' do
      let(:before_fetch_hook) { api.trash_file(file_sync.id) }
      it                      { expect(file).to be_deleted }
    end

    context 'when file is removed' do
      let(:before_fetch_hook) { api.delete_file(file_sync.id) }
      it                      { expect(file).to be_deleted }
    end
  end

  describe '#pull' do
    subject(:pull)          { syncable.pull }
    let(:external_id)       { file_sync.id }
    let(:before_pull_hook)  { nil }
    let(:syncable_from_db) do
      described_class.find_by!(external_id: file_sync.id)
    end

    before { before_pull_hook }
    before { pull }

    it { expect(syncable_from_db.name).to eq 'Test File' }
    it { expect(syncable_from_db.mime_type).to eq mime_type }
    it { expect(syncable_from_db.content_version).to eq '1' }
    it { expect(syncable_from_db.parent).to eq nil }
    it { expect(syncable_from_db).not_to be_deleted }

    context 'when file is trashed' do
      let(:before_pull_hook) { api.trash_file(file_sync.id) }
      it do
        expect(syncable_from_db.name).to eq nil
        expect(syncable_from_db.mime_type).to eq nil
        expect(syncable_from_db.content_version).to eq nil
        expect(syncable_from_db.parent).to eq nil
        expect(syncable).to be_deleted
      end
    end

    context 'when file is removed' do
      let(:before_pull_hook) { api.delete_file(file_sync.id) }
      it do
        expect(syncable_from_db.name).to eq nil
        expect(syncable_from_db.mime_type).to eq nil
        expect(syncable_from_db.content_version).to eq nil
        expect(syncable_from_db.parent).to eq nil
        expect(syncable).to be_deleted
      end
    end
  end
end
