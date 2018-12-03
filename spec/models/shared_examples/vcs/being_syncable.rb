# frozen_string_literal: true

require_relative 'having_remote.rb'

RSpec.shared_examples 'vcs: being syncable' do
  it_should_behave_like 'vcs: having remote' do
    let(:object) { syncable }
  end

  describe '#fetch' do
    subject               { syncable }
    let(:remote)          { instance_double syncable.send(:remote_class) }
    let(:file_is_deleted) { false }

    before do
      allow(syncable).to receive(:remote).and_return remote
      allow(remote).to receive(:name).and_return 'name'
      allow(remote).to receive(:mime_type).and_return 'mime_type'
      allow(remote).to receive(:content_version).and_return 'version'
      allow(remote).to receive(:parent_id).and_return 'parent_id'
      allow(syncable).to receive(:remote_parent_id=)
      allow(syncable).to receive(:thumbnail_from_remote)
      allow(remote).to receive(:deleted?).and_return false
    end

    after { syncable.fetch }

    it { expect(syncable).to receive(:name=).with('name') }
    it { expect(syncable).to receive(:mime_type=).with('mime_type') }
    it { expect(syncable).to receive(:content_version=).with('version') }
    it { expect(syncable).to receive(:remote_parent_id=).with('parent_id') }
    it { expect(syncable).to receive(:thumbnail_from_remote) }
    it { expect(syncable).to receive(:is_deleted=).with(false) }
  end

  describe '#pull' do
    subject(:pull) { syncable.pull }

    before do
      allow(syncable).to receive(:fetch)
      allow(syncable).to receive(:build_associations)
      allow(syncable).to receive(:save)
    end

    after { pull }

    it { expect(syncable).to receive(:fetch) }
    it { expect(syncable).to receive(:build_associations) }
    it { expect(syncable).to receive(:save) }

    context 'when passing force_sync: true' do
      subject(:pull) { syncable.pull(force_sync: true) }

      it 'sets force_sync attribute on syncable' do
        pull
        expect(syncable.force_sync).to be true
      end
    end
  end

  describe '#pull_children' do
    before do
      allow(syncable)
        .to receive(:children_from_remote).and_return 'children'
    end
    after { syncable.pull_children }
    it    { expect(syncable).to receive(:children_in_branch=).with('children') }
  end

  describe '#reload' do
    before  { allow(described_class).to receive(:find) }
    after   { syncable.reload }
    it      { expect(syncable).to receive(:reset_remote) }
  end

  describe '#remote_parent_id=(parent_id)' do
    subject(:set_parent_id) { syncable.send(:remote_parent_id=, parent_id) }
    let(:parent_id)         { 'id-of-parent' }
    let(:before_hook)       { nil }

    before { before_hook }
    before { set_parent_id }

    it { expect(syncable.parent_in_branch).to eq nil }

    context 'when record with parent id exists' do
      let(:existing_record) { syncable.dup }
      let(:before_hook) { existing_record.update(remote_file_id: parent_id) }

      it { expect(syncable.parent_in_branch).to eq existing_record }
    end
  end

  describe '#thumbnail_from_remote' do
    subject(:set_thumbnail) { syncable.send(:thumbnail_from_remote) }
    let(:remote)            { instance_double syncable.send(:remote_class) }
    let(:has_thumbnail)     { true }

    before do
      allow(syncable).to receive(:remote).and_return remote
      allow(remote).to receive(:thumbnail?).and_return has_thumbnail
    end

    it 'finds or initializes thumbnail by file resource' do
      stub      = class_double VCS::FileThumbnail
      thumbnail = instance_double VCS::FileThumbnail
      expect(VCS::FileThumbnail)
        .to receive(:create_with).with(raw_image: anything).and_return stub
      expect(stub)
        .to receive(:find_or_initialize_by_file_in_branch)
        .with(syncable)
        .and_return thumbnail
      expect(syncable).to receive(:thumbnail=).with(thumbnail)
      set_thumbnail
    end

    context 'when remote#thumbnail? is false' do
      let(:has_thumbnail) { false }
      it                  { is_expected.to be nil }
    end
  end

  describe '#thumbnail_version_id' do
    subject(:thumbnail_version) { syncable.thumbnail_version_id }
    let(:remote) { nil }

    before { allow(syncable).to receive(:remote).and_return remote }

    it { is_expected.to be nil }

    context 'when sync adapter is present' do
      let(:remote) { instance_double Providers::GoogleDrive::FileSync }
      before do
        allow(remote).to receive(:thumbnail_version).and_return 'version'
      end

      it { is_expected.to eq 'version' }
    end
  end
end
