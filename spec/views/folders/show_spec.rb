# frozen_string_literal: true

RSpec.describe 'folders/show', type: :view do
  let(:folder)            { nil }
  let(:project)           { build_stubbed :project }
  let(:file_snapshots)    { build_stubbed_list :file_resource_snapshot, 5 }
  let(:folder_snapshots) do
    build_stubbed_list :file_resource_snapshot, 5, :folder
  end
  let(:ancestors)         { [] }
  let(:children)          { subfolders + subfiles }
  let(:subfolders) do
    folder_snapshots.map do |snapshot|
      Stage::FileDiff.new(project: project,
                          staged_snapshot: snapshot,
                          committed_snapshot: snapshot)
    end
  end
  let(:subfiles) do
    file_snapshots.map do |snapshot|
      Stage::FileDiff.new(project: project,
                          staged_snapshot: snapshot,
                          committed_snapshot: snapshot)
    end
  end
  let(:action) { 'root' }

  before do
    assign(:project,      project)
    assign(:folder,       folder)
    assign(:children,     children)
    assign(:ancestors,    ancestors)
    controller.action_name = action
  end

  it 'renders the names of files and folders' do
    render
    children.each do |child|
      expect(rendered).to have_text child.name
    end
  end

  it 'renders the icons of files and folders' do
    render
    children.each do |child|
      expect(rendered).to have_css "img[src='#{view.asset_path(child.icon)}']"
    end
  end

  it 'renders the links of files' do
    render
    subfiles.each do |file|
      link = file.external_link
      expect(rendered)
        .to have_css "a[href='#{link}'][target='_blank']"
    end
  end

  it 'renders the links of folders' do
    render
    subfolders.each do |folder|
      expect(rendered).to have_link(
        folder.name,
        href: profile_project_folder_path(
          project.owner, project.slug, folder.external_id
        )
      )
    end
  end

  it 'renders a link to infos for each file' do
    render
    children.each do |file|
      link = profile_project_file_infos_path(project.owner,
                                             project,
                                             file.external_id)
      expect(rendered).to have_link(text: '', href: link)
    end
  end

  it 'does not have a button to capture changes' do
    render
    expect(rendered).not_to have_link(
      'Capture Changes',
      href: new_profile_project_revision_path(project.owner, project)
    )
  end

  context 'when current user can edit project' do
    before { assign(:user_can_commit_changes, true) }

    it 'has a button to capture changes' do
      render
      expect(rendered).to have_link(
        'Capture Changes',
        href: new_profile_project_revision_path(project.owner, project)
      )
    end
  end

  context 'when action name is show' do
    let(:action)      { 'show' }
    let(:ancestors)   { [parent, grandparent] }
    let(:grandparent) { build_stubbed :file_resource_snapshot, name: 'Docs' }
    let(:parent)      { build_stubbed :file_resource_snapshot, name: 'Other' }
    let(:folder)      { build_stubbed :file_resource_snapshot, name: 'Folder' }

    it 'renders breadcrumbs' do
      render
      expect(rendered).to have_css(
        '.breadcrumbs',
        text: 'Docs  Other  Folder'
      )
    end

    it 'renders current folder' do
      render
      expect(rendered).to have_text 'Folder'
    end

    it 'renders link to home-folder breadcrumb' do
      render
      expect(rendered).to have_link(
        '', href: profile_project_root_folder_path(project.owner, project)
      )
    end
  end

  context 'when file has been modified' do
    before { allow(children.first).to receive(:modified?).and_return(true) }

    it 'adds a file indicator' do
      render
      expect(rendered).to have_css '.file.modified .indicators svg', count: 1
    end
  end

  context 'when file has been added' do
    before { allow(children.first).to receive(:added?).and_return(true) }

    it 'adds a file indicator' do
      render
      expect(rendered).to have_css '.file.added .indicators svg', count: 1
    end
  end

  context 'when file has been moved' do
    before { allow(children.first).to receive(:moved?).and_return(true) }

    it 'adds a file indicator' do
      render
      expect(rendered).to have_css '.file.moved .indicators svg', count: 1
    end
  end

  context 'when file has been renamed' do
    before { allow(children.first).to receive(:renamed?).and_return(true) }

    it 'adds a file indicator' do
      render
      expect(rendered).to have_css '.file.renamed .indicators svg', count: 1
    end
  end

  context 'when file has been deleted' do
    before { allow(children.first).to receive(:deleted?).and_return(true) }

    it 'adds a file indicator' do
      render
      expect(rendered).to have_css '.file.deleted .indicators svg', count: 1
    end
  end

  context 'when file has been moved, renamed, and modified' do
    before do
      allow(children.first).to receive(:moved?).and_return(true)
      allow(children.first).to receive(:renamed?).and_return(true)
      allow(children.first).to receive(:modified?).and_return(true)
    end

    it 'adds 3 file indicators' do
      render
      expect(rendered).to have_css '.file.changed .indicators svg', count: 3
    end
  end
end
