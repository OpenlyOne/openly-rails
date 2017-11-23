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
    let!(:folder) do
      create :file_items_folder, google_drive_id: root_id, project: project
    end
    let(:root_id) { Settings.google_drive_test_folder_id }

    it 'creates 3 root-level files' do
      subject
      files = project.reload.root_folder.children
      expect(files.size).to eq 3
    end

    it 'creates 2 files in sub-folder' do
      subject
      subfolder = project.reload.root_folder.children.find do |f|
        f.model_name == 'FileItems::Folder'
      end
      expect(subfolder.children.size).to eq 2
    end

    it 'creates 1 file in sub-sub-folder' do
      subject
      subfolder = project.root_folder.children.find do |f|
        f.model_name == 'FileItems::Folder'
      end
      subsubfolder =
        subfolder.children.find { |f| f.model_name == 'FileItems::Folder' }
      expect(subsubfolder.children.size).to eq 1
    end

    context 'without recursive FolderImportJobs' do
      before do
        allow_any_instance_of(FolderImportJob)
          .to receive(:schedule_folder_import_job_for)
      end

      it 'creates 3 files' do
        expect { subject }
          .to change(FileItems::Base, :count).by(3)
      end
    end

    it 'creates 1 FolderImportJob' do
      expect(FolderImportJob).to receive(:perform_later)
        .with(
          reference: project,
          folder_id: FileItems::Folder.last.id
        )

      subject
    end
  end
end
