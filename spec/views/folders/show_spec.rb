# frozen_string_literal: true

RSpec.describe 'folders/show', type: :view do
  let(:folder)            { nil }
  let(:project)           { build_stubbed :project }
  let(:files)    { build_list :vcs_file_in_branch, 5, :unchanged }
  let(:folders)  { build_list :vcs_file_in_branch, 5, :folder, :unchanged }
  let(:ancestors)       { [] }
  let(:children)        { folders + files }
  let(:diffs)           { children.map(&:diff) }
  let(:action)          { 'root' }

  before do
    assign(:project,      project)
    assign(:folder,       folder)
    assign(:children,     children)
    assign(:ancestors,    ancestors)
    controller.action_name = action
  end

  it 'renders the names of files and folders' do
    render
    diffs.each do |diff|
      expect(rendered).to have_text diff.name
    end
  end

  it 'renders the thumbnails of files and folders' do
    thumbnail = create :vcs_file_thumbnail
    diffs.each do |diff|
      allow(diff.current_or_previous_version)
        .to receive(:thumbnail).and_return thumbnail
    end

    render

    diffs.each do |diff|
      expect(rendered).to have_css "img[src='#{diff.thumbnail_image.url}']"
    end
  end

  it 'renders the icons of files and folders' do
    render
    diffs.each do |diff|
      expect(rendered).to have_css "img[src='#{view.asset_path(diff.icon)}']"
    end
  end

  it 'renders the links of files' do
    render
    files.each do |file|
      link = file.link_to_remote
      expect(rendered).to have_css "a[href='#{link}'][target='_blank']"
    end
  end

  it 'renders the links of folders' do
    render
    folders.map(&:diff).each do |diff|
      expect(rendered).to have_link(
        diff.name,
        href: profile_project_folder_path(
          project.owner, project.slug, VCS::File.id_to_hashid(diff.file_id)
        )
      )
    end
  end

  it 'renders a link to infos for each file' do
    render
    diffs.each do |diff|
      link = profile_project_file_infos_path(
        project.owner,
        project,
        VCS::File.id_to_hashid(diff.file_id)
      )
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
    let(:action)          { 'show' }
    let(:ancestors)       { [parent, grandparent] }
    let(:grandparent)     { build_stubbed :vcs_version, name: 'Docs' }
    let(:parent)          { build_stubbed :vcs_version, name: 'Other' }
    let(:folder_version) { build_stubbed :vcs_version, name: 'Folder' }
    let(:folder) do
      build :vcs_file_in_branch, current_version: folder_version
    end

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

    it 'renders link to folders' do
      [grandparent, parent, folder_version].each do |ancestor|
        render
        expect(rendered).to have_link(
          ancestor.name,
          href: profile_project_folder_path(
            project.owner,
            project.slug,
            VCS::File.id_to_hashid(ancestor.file_id)
          )
        )
      end
    end

    it 'renders link to home-folder breadcrumb' do
      render
      expect(rendered).to have_link(
        '', href: profile_project_root_folder_path(project.owner, project)
      )
    end
  end

  context 'when file has been modified' do
    before { allow(diffs.first).to receive(:modification?).and_return(true) }

    it 'adds a file indicator' do
      render
      expect(rendered)
        .to have_css '.file.modification .indicators svg', count: 1
    end
  end

  context 'when file has been added' do
    before { allow(diffs.first).to receive(:addition?).and_return(true) }

    it 'adds a file indicator' do
      render
      expect(rendered).to have_css '.file.addition .indicators svg', count: 1
    end
  end

  context 'when file has been moved' do
    before { allow(diffs.first).to receive(:movement?).and_return(true) }

    it 'adds a file indicator' do
      render
      expect(rendered).to have_css '.file.movement .indicators svg', count: 1
    end
  end

  context 'when file has been renamed' do
    before { allow(diffs.first).to receive(:rename?).and_return(true) }

    it 'adds a file indicator' do
      render
      expect(rendered).to have_css '.file.rename .indicators svg', count: 1
    end
  end

  context 'when file has been deleted' do
    before { allow(diffs.first).to receive(:deletion?).and_return(true) }

    it 'adds a file indicator' do
      render
      expect(rendered).to have_css '.file.deletion .indicators svg', count: 1
    end
  end

  context 'when file has been moved, renamed, and modified' do
    before do
      allow(diffs.first).to receive(:movement?).and_return(true)
      allow(diffs.first).to receive(:rename?).and_return(true)
      allow(diffs.first).to receive(:modification?).and_return(true)
    end

    it 'adds 3 file indicators' do
      render
      expect(rendered).to have_css '.file.change .indicators svg', count: 3
    end
  end
end
