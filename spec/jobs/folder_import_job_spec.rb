# frozen_string_literal: true

RSpec.describe FolderImportJob, type: :job do
  subject(:job) { FolderImportJob.new }

  it { expect(subject.priority).to eq 100 }
  it { expect(subject.queue_name).to eq 'folder_import' }

  describe '#perform' do
    subject(:perform_job) { job.perform(x: 'y') }
    let(:file)            { instance_double FileResources::GoogleDrive }
    let(:subfolders)      { %w[sub1 sub2 sub3] }

    before do
      allow(job).to receive(:variables_from_arguments).with(x: 'y')
      allow(job).to receive(:staged_file_id).and_return 'file-id'
      allow(VCS::StagedFile).to receive(:find).with('file-id').and_return file
      allow(file).to receive(:pull_children)
      allow(file).to receive(:subfolders).and_return subfolders
      allow(job).to receive(:schedule_folder_import_job_for)
    end

    it 'calls #pull children' do
      perform_job
      expect(file).to have_received(:pull_children)
    end

    it 'creates a new import job for every subfolder' do
      perform_job
      expect(job).to have_received(:schedule_folder_import_job_for).with('sub1')
      expect(job).to have_received(:schedule_folder_import_job_for).with('sub2')
      expect(job).to have_received(:schedule_folder_import_job_for).with('sub3')
    end
  end

  describe '#schedule_folder_import_job_for(file_resource)' do
    subject(:schedule) { job.send :schedule_folder_import_job_for, staged_file }
    let(:staged_file) { instance_double VCS::StagedFile }

    before do
      allow(job).to receive(:setup).and_return 'setup'
      allow(staged_file).to receive(:id).and_return 'file-id'
      allow(FolderImportJob).to receive(:perform_later)
    end

    it 'calls .perform_later' do
      schedule
      expect(FolderImportJob)
        .to have_received(:perform_later)
        .with(reference: 'setup',
              staged_file_id: 'file-id')
    end
  end
end
