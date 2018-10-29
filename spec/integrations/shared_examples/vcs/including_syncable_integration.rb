# frozen_string_literal: true

RSpec.shared_examples 'vcs: including syncable integration', :vcr do
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
    let(:update_content) do
      Providers::GoogleDrive::ApiConnection
        .default
        .update_file_content(file_sync.id, 'new file content')
    end

    # Generate thumbnail and wait
    before { update_content }
    before { sleep 5 if VCR.current_cassette.recording? }
    before { before_fetch_hook }
    before { fetch }

    it 'sets correct attributes' do
      expect(syncable.name).to eq 'Test File'
      expect(syncable.mime_type).to eq mime_type
      expect(syncable.content_version.to_i).to be > 1
      expect(syncable.parent).to eq root
      expect(syncable.thumbnail).to be_present
      expect(syncable).not_to be_deleted
    end

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
    let(:update_content) do
      Providers::GoogleDrive::ApiConnection
        .default
        .update_file_content(file_sync.id, 'new file content')
    end

    # Generate thumbnail and wait
    before { update_content }
    before { sleep 5 if VCR.current_cassette.recording? }
    before { before_pull_hook }
    before { pull }

    it 'sets correct attributes' do
      expect(syncable_from_db.name).to eq 'Test File'
      expect(syncable_from_db.mime_type).to eq mime_type
      expect(syncable_from_db.content_version.to_i).to be > 1
      expect(syncable_from_db.parent).to eq root
      expect(syncable_from_db.thumbnail).to be_present
      expect(syncable_from_db).not_to be_deleted
    end

    context 'when file is trashed' do
      let(:before_pull_hook) { api.trash_file(file_sync.id) }
      it do
        expect(syncable_from_db.name).to eq nil
        expect(syncable_from_db.mime_type).to eq nil
        expect(syncable_from_db.content_version).to eq nil
        expect(syncable_from_db.parent).to eq nil
        expect(syncable_from_db.thumbnail).to eq nil
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
        expect(syncable_from_db.thumbnail).to eq nil
        expect(syncable).to be_deleted
      end
    end
  end

  describe '#pull_children' do
    let(:external_id) { file_sync.id }
    let(:mime_type)   { folder_mime_type }
    let(:syncable_from_db) do
      described_class.find_by!(external_id: external_id)
    end

    let(:subfile1) { file_sync_class.create(attributes.merge(name: 'sub1')) }
    let(:subfile2) { file_sync_class.create(attributes.merge(name: 'sub2')) }
    let(:attributes) { { parent_id: external_id, mime_type: mime_type } }

    before { subfile1 && subfile2 }
    before { syncable.pull && syncable.pull_children }

    it 'has children subfile1 and subfile2' do
      expect(syncable_from_db.children.map(&:external_id))
        .to contain_exactly subfile1.id, subfile2.id
    end

    context 'when subfile1 is deleted and subfile3 is added' do
      let(:subfile3) { file_sync_class.create(attributes.merge(name: 'sub3')) }
      before { api.delete_file(subfile1.id) }
      before { subfile3 }

      it 'updates children to subfile2 and subfile3' do
        syncable.reload.pull_children
        expect(syncable_from_db.children.map(&:external_id))
          .to contain_exactly subfile2.id, subfile3.id
      end
    end
  end
end
