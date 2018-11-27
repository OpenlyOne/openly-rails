# frozen_string_literal: true

RSpec.describe FileHelper, type: :helper do
  describe '#link_to_file(file, folder_path, path_parameters, options = {})' do
    subject(:method)  { helper.link_to_file(file, folder_path, path_params) {} }
    let(:folder_path) { 'folder_path' }
    let(:path_params) { %w[p1 p2] }
    let(:file)        { instance_double VCS::FileInBranch }
    let(:diff)        { instance_double VCS::FileDiff }
    let(:is_folder)   { false }

    before do
      allow(file).to receive(:diff).and_return diff
      allow(diff).to receive(:folder?).and_return is_folder
      allow(diff).to receive(:hashed_file_id).and_return 'hashed-file-id'
      allow(file).to receive(:link_to_remote).and_return 'remote-link'
      allow(helper)
        .to receive(:send)
        .with(folder_path, *path_params, 'hashed-file-id')
        .and_return 'folder-path-with-params-and-hashed-file-id'
    end

    context 'when file is folder' do
      let(:is_folder) { true }

      it 'returns internal link to directory' do
        expect(helper).to receive(:link_to).with(
          'folder-path-with-params-and-hashed-file-id',
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

      it 'sets url to link_to_remote_for_file' do
        expect(helper).to receive(:link_to).with('remote-link', kind_of(Hash))
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
      subject(:method) do
        helper.link_to_file(file, folder_path, path_params, options) {}
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

  describe '#link_to_file_backup(file, revision, project, opts = {}, &block)' do
    subject(:method) do
      helper.link_to_file_backup(version, revision, project) {}
    end
    let(:version)     { instance_double VCS::Version }
    let(:backup_path) { 'some-path' }
    let(:revision)    { instance_double VCS::Commit }
    let(:project)     { instance_double Project }
    let(:is_folder)   { false }

    before do
      allow(version).to receive(:folder?).and_return(is_folder)
      allow(helper)
        .to receive(:file_backup_path)
        .with(version, revision, project)
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
        helper.link_to_file_backup(version, revision, project, options) {}
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
      helper.link_to_file_backup?(version, revision, project)
    end
    let(:version)   { instance_double VCS::Version }
    let(:revision)  { instance_double VCS::Commit }
    let(:project)   { instance_double Project }

    before do
      allow(helper)
        .to receive(:file_backup_path)
        .with(version, revision, project)
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

  describe '#file_backup_path(diff, revision, project)' do
    subject(:method) { helper.send(:file_backup_path, file, revision, project) }
    let(:file)          { instance_double VCS::Version }
    let(:revision)      { instance_double VCS::Commit }
    let(:project)       { instance_double Project }
    let(:is_folder)     { false }
    let(:backup) { nil }
    let(:file_resource) { instance_double VCS::FileInBranch }

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
        allow(revision).to receive(:id).and_return 'revision-id'
        allow(revision).to receive(:published?).and_return is_published
        allow(file).to receive(:hashed_file_id).and_return 'hashed-file-id'
      end

      it do
        is_expected.to eq profile_project_revision_folder_path(
          'owner',
          'project',
          'revision-id',
          'hashed-file-id'
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
        allow(backup).to receive(:link_to_remote).and_return 'remote'
      end

      it { is_expected.to eq 'remote' }
    end

    context 'when file does not have backup' do
      it { is_expected.to eq nil }
    end
  end
end
