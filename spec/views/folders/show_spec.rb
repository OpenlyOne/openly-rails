# frozen_string_literal: true

RSpec.describe 'folders/show', type: :view do
  before { allow(NotificationChannelJob).to receive(:perform_later) }
  let(:folder)            { create(:file_items_folder, parent: nil) }
  let(:project)           { folder.project }
  let(:files_and_folders) { files + folders }
  let(:files) do
    create_list(:file_items_base, 5, project: project, parent: folder)
  end
  let(:folders) do
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
      expect(rendered).to have_css "img[src='#{view.asset_path(file.icon)}']"
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

  context 'when folder is not root' do
    let(:folder) do
      create :file_items_folder, project: parent.project, parent: parent
    end
    let(:parent) { create :file_items_folder }

    it 'renders breadcrumbs' do
      render
      expect(rendered).to have_css 'nav'
    end

    it 'renders current folder' do
      render
      expect(rendered).to have_text folder.name
    end

    it 'renders link to home-folder breadcrumb' do
      render
      expect(rendered).to have_link(
        '', href: profile_project_root_folder_path(project.owner, project)
      )
    end
  end

  context 'when file version differs from version_at_last_commit' do
    before { files.first.version = 100 }
    it 'adds a file modified indicator' do
      render
      expect(rendered).to have_css '.indicators svg.file-modified', count: 1
    end
  end
end
