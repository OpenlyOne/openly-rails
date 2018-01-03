# frozen_string_literal: true

RSpec.describe 'folders/show', type: :view do
  let(:folder)            { create :file, :root, repository: repository }
  let(:project)           { create :project }
  let(:repository)        { project.repository }
  let(:files_and_folders) { files + folders }
  let(:files)             { create_list :file, 5, parent: folder }
  let(:folders)           { create_list :file, 5, :folder, parent: folder }
  let(:ancestors)         { [] }

  before do
    assign(:project, project)
    assign(:folder, folder)
    assign(:files, files_and_folders)
    assign(:ancestors, ancestors)
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
      icon = view.icon_for_file(file)
      expect(rendered).to have_css "img[src='#{view.asset_path(icon)}']"
    end
  end

  it 'renders the links of files' do
    render
    files.each do |file|
      link = view.external_link_for_file(file)
      expect(rendered)
        .to have_css "a[href='#{link}'][target='_blank']"
    end
  end

  it 'renders the links of folders' do
    render
    folders.each do |folder|
      expect(rendered).to have_link(
        folder.name,
        href: profile_project_folder_path(
          project.owner, project.slug, folder.id
        )
      )
    end
  end

  context 'when folder is not root' do
    let(:folder)    { create :file, :folder, name: 'Folder',  parent: other }
    let(:other)     { create :file, :folder, name: 'Other',   parent: docs }
    let(:docs)      { create :file, :folder, name: 'Docs',    parent: root }
    let(:root)      { create :file, :root, repository: project.repository }
    let(:ancestors) { folder.ancestors }

    it 'renders breadcrumbs' do
      render
      expect(rendered).to have_css(
        '.breadcrumbs',
        text: 'Docs  Other  Folder'
      )
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

  xcontext 'when file has been modified' do
    before do
      allow(files.first)
        .to receive(:modified_since_last_commit?).and_return(true)
    end

    it 'adds a file indicator' do
      render
      expect(rendered).to have_css '.indicators svg', count: 1
    end
  end

  xcontext 'when file has been added' do
    before do
      allow(files.first)
        .to receive(:added_since_last_commit?).and_return(true)
    end

    it 'adds a file indicator' do
      render
      expect(rendered).to have_css '.indicators svg', count: 1
    end
  end

  xcontext 'when file has been moved' do
    before do
      allow(files.first)
        .to receive(:moved_since_last_commit?).and_return(true)
    end

    it 'adds a file indicator' do
      render
      expect(rendered).to have_css '.indicators svg', count: 1
    end
  end

  xcontext 'when file has been deleted' do
    before do
      allow(files.first)
        .to receive(:deleted_since_last_commit?).and_return(true)
    end

    it 'adds a file indicator' do
      render
      expect(rendered).to have_css '.indicators svg', count: 1
    end
  end
end
