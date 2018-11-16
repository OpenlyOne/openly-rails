# frozen_string_literal: true

RSpec.describe FileHelper, type: :helper do
  describe '#link_to_file(file, project, options = {})' do
    subject(:method)  { helper.link_to_file(file, project) {} }
    let(:project)     { build_stubbed :project }
    let(:file)        { instance_double VCS::FileSnapshot }
    let(:is_folder)   { false }

    before { allow(file).to receive(:folder?).and_return is_folder }
    before { allow(file).to receive(:external_id).and_return 'external-id' }
    before { allow(file).to receive(:external_link).and_return 'external-link' }

    context 'when file is folder' do
      let(:is_folder) { true }

      it 'returns internal link to directory' do
        expect(helper).to receive(:link_to).with(
          "/#{project.owner.handle}/#{project.slug}/folders/external-id",
          any_args
        )
        method
      end

      it 'does not set target to _blank' do
        expect(helper).to receive(:link_to).with(kind_of(String), {})
        method
      end
    end

    context 'when file is not directory' do
      let(:is_folder) { false }

      it 'sets url to external_link_for_file' do
        expect(helper).to receive(:link_to).with('external-link', kind_of(Hash))
        method
      end

      it 'sets target to _blank' do
        expect(helper).to receive(:link_to).with(
          kind_of(String),
          hash_including(target: '_blank')
        )
        method
      end
    end

    context 'when options are passed' do
      subject(:method)  { helper.link_to_file(file, project, options) {} }
      let(:options)     { {} }

      it 'does not modify the passed options hash' do
        expect { method }.not_to(change { options })
      end

      context "when options include target: '_blank'" do
        let(:options) { { target: '_blank' } }

        it 'passes options to #link_to' do
          expect(helper)
            .to receive(:link_to)
            .with(kind_of(String), hash_including(target: '_blank'))
          method
        end
      end
    end
  end

  describe '#link_to_file_backup(file, revision, project, opts = {}, &block)' do
    subject(:method) do
      helper.link_to_file_backup(snapshot, revision, project) {}
    end
    let(:snapshot)    { instance_double VCS::FileSnapshot }
    let(:backup_path) { 'some-path' }
    let(:revision)    { instance_double VCS::Commit }
    let(:project)     { instance_double Project }
    let(:is_folder)   { false }

    before do
      allow(snapshot).to receive(:folder?).and_return(is_folder)
      allow(helper)
        .to receive(:file_backup_path)
        .with(snapshot, revision, project)
        .and_return backup_path
    end

    it 'returns url to backup' do
      expect(helper).to receive(:link_to).with(backup_path, kind_of(Hash))
      method
    end

    it 'sets target to _blank' do
      expect(helper).to receive(:link_to).with(
        backup_path,
        hash_including(target: '_blank')
      )
      method
    end

    context 'when file is folder' do
      let(:is_folder) { true }

      it 'does not set target to _blank' do
        expect(helper).to receive(:link_to).with(
          kind_of(String),
          hash_excluding(target: '_blank')
        )
        method
      end
    end

    context 'when file_backup_path is nil' do
      let(:backup_path) { nil }

      it 'returns content tag span' do
        expect(helper).to receive(:content_tag).with(:span)
        method
      end
    end

    context 'when options are passed' do
      subject(:method) do
        helper.link_to_file_backup(snapshot, revision, project, options) {}
      end
      let(:options) { {} }

      it 'does not modify the passed options hash' do
        expect { method }.not_to(change { options })
      end

      context "when options include target: '_blank'" do
        let(:options) { { target: '_blank' } }

        it 'passes options to #link_to' do
          expect(helper)
            .to receive(:link_to)
            .with(kind_of(String), hash_including(target: '_blank'))
          method
        end
      end
    end
  end

  describe '#link_to_file_backup?(file, revision)' do
    subject(:method) do
      helper.link_to_file_backup?(snapshot, revision, project)
    end
    let(:snapshot)    { instance_double VCS::FileSnapshot }
    let(:revision)    { instance_double VCS::Commit }
    let(:project)     { instance_double Project }

    before do
      allow(helper)
        .to receive(:file_backup_path)
        .with(snapshot, revision, project)
        .and_return path
    end

    context 'when file has backup' do
      let(:path) { 'some-path' }

      it { is_expected.to be true }
    end

    context 'when file does not have backup' do
      let(:path) { nil }

      it { is_expected.to be false }
    end
  end

  describe '#file_backup_path(file, revision, project)' do
    subject(:method) { helper.send(:file_backup_path, file, revision, project) }
    let(:file)          { instance_double VCS::FileSnapshot }
    let(:revision)      { instance_double VCS::Commit }
    let(:project)       { instance_double Project }
    let(:is_folder)     { false }
    let(:backup) { nil }
    let(:file_resource) { instance_double VCS::StagedFile }

    before do
      allow(file).to receive(:folder?).and_return(is_folder)
      allow(file).to receive(:backup).and_return backup
    end

    context 'when file is folder' do
      let(:is_folder)     { true }
      let(:is_published)  { true }

      before do
        allow(project).to receive(:owner).and_return 'owner'
        allow(project).to receive(:to_param).and_return 'project'
        allow(revision).to receive(:id).and_return 'r-id'
        allow(revision).to receive(:published?).and_return is_published
        allow(file).to receive(:external_id).and_return 'ext-id'
      end

      it do
        is_expected.to eq profile_project_revision_folder_path(
          'owner',
          'project',
          'r-id',
          'ext-id'
        )
      end

      context 'when revision is not published' do
        let(:is_published) { false }

        it { is_expected.to eq nil }
      end
    end

    context 'when file has backup' do
      let(:backup) { instance_double VCS::FileBackup }

      before do
        allow(file).to receive(:backup).and_return backup
        allow(backup).to receive(:external_link).and_return 'external'
      end

      it { is_expected.to eq 'external' }
    end

    context 'when file does not have backup' do
      it { is_expected.to eq nil }
    end
  end
end
