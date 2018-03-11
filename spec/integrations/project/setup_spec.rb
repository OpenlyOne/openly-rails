# frozen_string_literal: true

RSpec.describe Project::Setup, type: :model do
  subject(:setup) { build :project_setup }
  let(:project)   { setup.project }
  let(:file)  { create :file_resource }
  let(:link)  { "https://drive.google.com/drive/folders/#{file.external_id}" }

  describe '#begin(attributes)', :delayed_job do
    before { setup.begin(link: link) }

    it 'sets root folder' do
      expect(project.staged_root_folder).to be_present
      expect(project.root_folder.id).to eq file.id
    end

    it 'creates a FolderImportJob' do
      expect(setup.folder_import_jobs.count).to eq 1
    end

    it 'creates a SetupCompletionCheckJob' do
      expect(setup.setup_completion_check_jobs.count).to eq 1
    end
  end

  describe '#check_if_complete', :delayed_job do
    let(:hook) { nil }

    before { setup.begin(link: link) }
    before { hook }
    before { setup.check_if_complete }

    it { expect(setup).not_to be_completed }

    context 'when all FileImportJobs are gone (processed)' do
      let(:hook) { setup.folder_import_jobs.delete_all }

      it { expect(setup).to be_completed }

      it 'creates an origin revision' do
        expect(project.revisions).to be_any
        expect(project.revisions.first.title).to eq 'Import Files'
      end
    end
  end
end
