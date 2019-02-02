# frozen_string_literal: true

RSpec.shared_examples 'vcs: being versionable' do
  describe 'associations' do
    it do
      is_expected.to belong_to(:current_version)
        .class_name('VCS::Version')
        .validate(false).autosave(false).optional
    end
  end

  describe 'callbacks' do
    before do
      allow(versionable).to receive(:clear_version)
      allow(versionable).to receive(:version!)
    end

    describe 'before_save' do
      subject       { versionable }
      let(:deleted) { false }

      before  { allow(versionable).to receive(:deleted?).and_return deleted }
      after   { versionable.save }

      it      { is_expected.not_to receive(:clear_version) }

      context 'when file is deleted' do
        let(:deleted) { true }

        it { is_expected.to receive(:clear_version) }
      end
    end

    describe 'after_save' do
      subject                               { versionable }
      let(:deleted)                         { false }

      before { allow(versionable).to receive(:deleted?).and_return deleted }

      after { versionable.save }

      it    { is_expected.to receive(:version!) }

      context 'when file is deleted' do
        let(:deleted) { true }

        it { is_expected.not_to receive(:version!) }
      end
    end
  end

  describe '#versionable_attributes' do
    subject { versionable.send :versionable_attributes }

    before do
      allow(versionable).to receive(:file_id).and_return 'file-id'
      allow(versionable).to receive(:remote_file_id).and_return 'remote-file-id'
      allow(versionable).to receive(:parent_id).and_return 'parent-id'
      allow(versionable).to receive(:name).and_return 'name'
      allow(versionable).to receive(:mime_type).and_return 'mime-type'
      allow(versionable).to receive(:content_id).and_return 'content_id'
      allow(versionable).to receive(:thumbnail_id).and_return 'thumbnail_id'
    end

    it 'returns a hash of the above attributes' do
      is_expected.to include(
        file_id: 'file-id',
        remote_file_id: 'remote-file-id',
        parent_id: 'parent-id',
        name: 'name',
        mime_type: 'mime-type',
        content_id: 'content_id',
        thumbnail_id: 'thumbnail_id'
      )
    end
  end

  describe '#version!' do
    subject(:capture_version)    { versionable.send :version! }
    let(:version)                { instance_double VCS::Version }

    before do
      allow(VCS::Version)
        .to receive(:for)
        .with(attribute: 'attr')
        .and_return version
      allow(versionable).to receive(:current_version=).with(version)
      allow(versionable).to receive(:current_version).and_return(version)
      allow(versionable)
        .to receive(:versionable_attributes).and_return(attribute: 'attr')
      allow(version).to receive(:id).and_return 123
      allow(versionable).to receive(:update_column)
    end

    after { capture_version }

    it 'calls for .for on VCS::Version and sets current_version' do
      expect(VCS::Version)
        .to receive(:for)
        .with(attribute: 'attr')
        .and_return(version)
      expect(versionable).to receive(:current_version=).with(version)
    end

    it 'updates column to id of created version' do
      expect(versionable)
        .to receive(:update_column).with('current_version_id', 123)
    end
  end
end
