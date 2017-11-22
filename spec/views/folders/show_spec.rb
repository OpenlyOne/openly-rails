# frozen_string_literal: true

RSpec.describe 'folders/show', type: :view do
  let(:project)           { create(:project) }
  let(:folder)            { create(:file_items_folder, project: project) }
  let(:files_and_folders) { files + folders }
  let(:files)             do
    create_list(:file_items_file, 5, project: project, parent: folder)
  end
  let(:folders)           do
    create_list(:file_items_folder, 5, project: project, parent: folder)
  end

  before do
    assign(:project, project)
    assign(:folder, folder)
    assign(:files, files_and_folders)
  end

  it 'renders the names of files and folders' do
    render
    files_and_folders.each do |file|
      expect(rendered).to have_text file.name
    end
  end

  it 'renders the icons of files and folders' do
    render
    files_and_folders.each do |file|
      expect(rendered).to have_css "img[src='#{file.icon}']"
    end
  end

  it 'renders the links of files' do
    render
    files.each do |file|
      expect(rendered)
        .to have_css "a[href='#{file.external_link}'][target='_blank']"
    end
  end

  it 'renders the links of folders' do
    render
    folders.each do |folder|
      expect(rendered).to have_link(
        folder.name,
        href: profile_project_folder_path(
          project.owner, project.slug, folder.google_drive_id
        )
      )
    end
  end
end
