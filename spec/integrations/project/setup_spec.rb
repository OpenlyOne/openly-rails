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
  end
end
