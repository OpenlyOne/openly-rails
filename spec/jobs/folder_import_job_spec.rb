# frozen_string_literal: true

RSpec.describe FolderImportJob, type: :job do
  subject(:job) { FolderImportJob.new }
  let(:project) { instance_double Project }

  before do
    allow(Project).to receive(:find).and_return project
  end

  describe 'priority' do
    it { expect(subject.priority).to eq 100 }
  end

  describe 'queue' do
    it { expect(subject.queue_name).to eq 'folder_import' }
  end

  describe '#perform' do
    subject(:method) do
      job.perform(reference: project, folder_id: 'folder-id')
    end
    let(:files)   { [file1, file2, file3] }
    let(:file1)   { instance_double Google::Apis::DriveV3::File }
    let(:file2)   { instance_double Google::Apis::DriveV3::File }
    let(:file3)   { instance_double Google::Apis::DriveV3::File }
    let(:staged_file1)  { instance_double VersionControl::Files::Staged }
    let(:staged_file2)  { instance_double VersionControl::Files::Staged }
    let(:staged_file3)  { instance_double VersionControl::Files::Staged }

    before do
      allow(job).to receive(:create_or_update_file)
        .and_return(staged_file1, staged_file2, staged_file3)
      allow(job).to receive(:schedule_folder_import_job_for)
      allow(GoogleDrive)
        .to receive(:list_files_in_folder).with('folder-id').and_return files
      allow(staged_file1).to receive(:id).and_return 'file1'
      allow(staged_file1).to receive(:directory?).and_return false
      allow(staged_file2).to receive(:id).and_return 'folder1'
      allow(staged_file2).to receive(:directory?).and_return true
      allow(staged_file3).to receive(:id).and_return 'folder2'
      allow(staged_file3).to receive(:directory?).and_return true
    end

    after { method }

    it 'calls #create_or_update_file three times' do
      expect(job).to receive(:create_or_update_file)
        .with(file1, 'folder-id', project).and_return staged_file1
      expect(job).to receive(:create_or_update_file)
        .with(file2, 'folder-id', project).and_return staged_file2
      expect(job).to receive(:create_or_update_file)
        .with(file3, 'folder-id', project).and_return staged_file3
    end

    it 'recursively creates two FolderImportJobs' do
      expect(job).to receive(:schedule_folder_import_job_for).with('folder1')
      expect(job).to receive(:schedule_folder_import_job_for).with('folder2')
    end
  end

  describe '#create_or_update_file' do
    subject(:method) do
      FolderImportJob.new.send :create_or_update_file, file, parent.id, project
    end
    let(:file) { build :google_drive_file, :with_id, :with_version_and_time }
    let(:parent)      { create :file, :root, repository: project.repository }
    let(:project)     { create :project }
    let(:saved_file)  { project.files.find(file.id) }

    context 'when file does not exist' do
      before { method }

      it 'creates the file' do
        expect(saved_file).to have_attributes(
          id: file.id,
          name: file.name,
          mime_type: file.mime_type,
          parent_id: parent.id,
          version: file.version,
          modified_time: file.modified_time
        )
      end
    end

    context 'when file already exists' do
      let(:existing_file) do
        build :google_drive_file, :with_id, :with_version_and_time,
              id: file.id, mime_type: file.mime_type
      end
      before do
        FolderImportJob.new.send :create_or_update_file, existing_file,
                                 parent.id, project
      end

      context 'when version is newer than existing file' do
        before { file.version = existing_file.version + 5 }
        before { method }

        it 'updates file attributes' do
          expect(saved_file).to have_attributes(
            id: file.id,
            name: file.name,
            mime_type: file.mime_type,
            parent_id: parent.id,
            version: file.version,
            modified_time: file.modified_time
          )
        end
      end

      context 'when version is older than existing file' do
        before { file.version = existing_file.version - 5 }
        before { method }

        it 'does not update file attributes' do
          expect(saved_file).to have_attributes(
            id: existing_file.id,
            name: existing_file.name,
            mime_type: existing_file.mime_type,
            parent_id: parent.id,
            version: existing_file.version,
            modified_time: existing_file.modified_time
          )
        end
      end
    end
  end
end
