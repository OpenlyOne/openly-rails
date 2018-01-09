# frozen_string_literal: true

RSpec.describe FolderImportJob, type: :job do
  subject(:job) { FolderImportJob.perform_later({}) }

  describe 'priority', delayed_job: true do
    it { expect(subject.priority).to eq 100 }
  end

  describe 'queue', delayed_job: true do
    it { expect(subject.queue_name).to eq 'folder_import' }
  end

  describe '#perform' do
    before do
      mock_google_drive_requests if ENV['MOCK_GOOGLE_DRIVE_REQUESTS'] == 'true'
    end
    subject(:method) do
      FolderImportJob.perform_later(reference: project, folder_id: folder.id)
    end
    let(:project) { create :project }
    let(:root_id) { Settings.google_drive_test_folder_id }
    let(:folder) do
      create :file, :root, id: root_id, repository: project.repository
    end

    it 'creates 3 root-level files' do
      subject
      expect(project.files.root.children.size).to eq 3
    end

    it 'creates 2 files in sub-folder' do
      subject
      subfolder = project.files.root.children.find(&:directory?)
      expect(subfolder.children.size).to eq 2
    end

    it 'creates 1 file in sub-sub-folder' do
      subject
      subfolder     = project.files.root.children.find(&:directory?)
      subsubfolder  = subfolder.children.find(&:directory?)
      expect(subsubfolder.children.size).to eq 1
    end

    context 'without recursive FolderImportJobs' do
      before do
        allow_any_instance_of(FolderImportJob)
          .to receive(:schedule_folder_import_job_for)
      end

      it 'creates 3 files' do
        folder
        expect { subject }.to change { project.files.count }.by(3)
      end
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
