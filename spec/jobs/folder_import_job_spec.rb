# frozen_string_literal: true

RSpec.describe FolderImportJob, type: :job do
  subject(:job) { FolderImportJob.new }

  it { expect(subject.priority).to eq 100 }
  it { expect(subject.queue_name).to eq 'folder_import' }

  describe '#perform' do
    subject(:method)  { job.perform(x: 'y') }
    let(:file)        { instance_double FileResources::GoogleDrive }

    before do
      allow(job).to receive(:variables_from_arguments).with(x: 'y')
      allow(job).to receive(:file_resource_id).and_return 'file-id'
      allow(FileResources::GoogleDrive)
        .to receive(:find).with('file-id').and_return file
      allow(file).to receive(:children).and_return []
      allow(file).to receive(:pull_children)
      allow(file).to receive(:subfolders).and_return []
    end

    it 'stages existing children' do
      expect(file).to receive(:children).and_return %w[c1 c2 c3]
      project = instance_double Project
      expect(job).to receive(:project).exactly(3).times.and_return project
      staged_files = class_double StagedFile
      expect(project)
        .to receive(:staged_files).exactly(3).times.and_return staged_files
      expect(staged_files).to receive(:create).with(file_resource: 'c1')
      expect(staged_files).to receive(:create).with(file_resource: 'c2')
      expect(staged_files).to receive(:create).with(file_resource: 'c3')
      subject
    end

    it 'calls #pull children' do
      expect(file).to receive(:pull_children)
      subject
    end

    it 'creates a new import job for every subfolder' do
      expect(file).to receive(:subfolders).and_return %w[sub1 sub2 sub3]
      expect(job).to receive(:schedule_folder_import_job_for).with('sub1')
      expect(job).to receive(:schedule_folder_import_job_for).with('sub2')
      expect(job).to receive(:schedule_folder_import_job_for).with('sub3')
      subject
    end
  end

  describe '#schedule_folder_import_job_for(file_resource)' do
    subject { job.send :schedule_folder_import_job_for, file_resource }
    let(:file_resource) { instance_double FileResource }

    before do
      allow(job).to receive(:setup).and_return 'setup'
      allow(file_resource).to receive(:id).and_return 'file-id'
    end

    it 'calls .perform_later' do
      expect(FolderImportJob)
        .to receive(:perform_later)
        .with(reference: 'setup',
              file_resource_id: 'file-id')
      subject
    end
  end
end
