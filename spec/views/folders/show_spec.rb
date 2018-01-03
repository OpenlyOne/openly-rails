# frozen_string_literal: true

RSpec.describe 'folders/show', type: :view do
  let(:folder)            { create :file, :root, repository: repository }
  let(:project)           { create :project }
  let(:repository)        { project.repository }
  let(:files_and_folders) { files + folders }
  let(:files)             { create_list :file, 5, parent: folder }
  let(:folders)           { create_list :file, 5, :folder, parent: folder }
  let(:ancestors)         { [] }
  let(:revision_diff)     { instance_double VersionControl::RevisionDiff }
  let(:folder_diff) do
    VersionControl::FileDiff.new(revision_diff, folder, folder)
  end
  let(:file_diffs) do
    files_and_folders.map do |file|
      VersionControl::FileDiff.new(revision_diff, file, file)
    end
  end

  before do
    assign(:project,      project)
    assign(:folder_diff,  folder_diff)
    assign(:file_diffs,   file_diffs)
    assign(:ancestors,    ancestors)
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

  it 'does not have a button to commit changes' do
    render
    expect(rendered).not_to have_link(
      'Commit Changes',
      href: new_profile_project_revision_path(project.owner, project)
    )
  end

  context 'when current user can edit project' do
    before { assign(:user_can_commit_changes, true) }

    it 'has a button to commit changes' do
      render
      expect(rendered).to have_link(
        'Commit Changes',
        href: new_profile_project_revision_path(project.owner, project)
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

  context 'when file has been modified' do
    before do
      allow(file_diffs.first).to receive(:been_modified?).and_return(true)
    end

    it 'adds a file indicator' do
      render
      expect(rendered).to have_css '.file.modified .indicators svg', count: 1
    end
  end

  context 'when file has been added' do
    before do
      allow(file_diffs.first).to receive(:been_added?).and_return(true)
    end

    it 'adds a file indicator' do
      render
      expect(rendered).to have_css '.file.added .indicators svg', count: 1
    end
  end

  context 'when file has been moved' do
    before do
      allow(file_diffs.first).to receive(:been_moved?).and_return(true)
    end

    it 'adds a file indicator' do
      render
      expect(rendered).to have_css '.file.moved .indicators svg', count: 1
    end
  end

  context 'when file has been deleted' do
    before do
      allow(file_diffs.first).to receive(:been_deleted?).and_return(true)
    end

    it 'adds a file indicator' do
      render
      expect(rendered).to have_css '.file.deleted .indicators svg', count: 1
    end
  end
end
