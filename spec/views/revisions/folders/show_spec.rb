# frozen_string_literal: true

RSpec.describe 'revisions/folders/show', type: :view do
  let(:folder)    { nil }
  let(:project)   { build_stubbed :project, :with_repository }
  let(:master)    { project.master_branch }
  let(:revision)  { build_stubbed :vcs_commit, :published, branch: master }
  let(:children)  { build_stubbed_list :vcs_version, 5 }
  let(:ancestors) { [] }
  let(:action)    { 'root' }

  before do
    assign(:project,    project)
    assign(:revision,   revision)
    assign(:children,   children)
    assign(:folder,     folder)
    assign(:ancestors,  ancestors)
    controller.action_name = action
  end

  # Overwrite the render method to include locals
  def render
    allow(view).to receive(:parent_layout)
    file_name = self.class.top_level_description
    super(
      template: file_name,
      layout: "layouts/#{file_name.rpartition('/').first}"
    )
  end

  it 'renders revision metadata' do
    render
    expect(rendered).to have_text(revision.title)
    expect(rendered).to have_text(revision.author.name)
    expect(rendered)
      .to have_text("#{time_ago_in_words(revision.created_at)} ago")
  end

  it 'has a link to the revision root folder path' do
    render
    expect(rendered).to have_link(
      revision.title,
      href: profile_project_revision_root_folder_path(
        project.owner, project, revision
      )
    )
  end

  it 'has a link to the revisions page' do
    render
    expect(rendered).to have_link(
      "#{time_ago_in_words(revision.created_at)} ago",
      href: profile_project_revisions_path(
        project.owner, project, anchor: revision
      )
    )
  end

  it 'has a button to restore the revision' do
    render
    restore_action = profile_project_revision_restores_path(
      project.owner, project, revision.id
    )

    expect(rendered).to have_css(
      'form'\
      "[action='#{restore_action}']"\
      "[method='post']",
      text: 'Restore Revision'
    )
  end

  it 'renders the names of files and folders' do
    render
    children.each do |child|
      expect(rendered).to have_text child.name
    end
  end

  it 'renders the thumbnails of files and folders' do
    thumbnail = create :vcs_file_thumbnail
    children.each do |child|
      allow(child)
        .to receive(:thumbnail).and_return thumbnail
    end

    render

    children.each do |child|
      expect(rendered).to have_css "img[src='#{child.thumbnail_image.url}']"
    end
  end

  it 'renders the icons of files and folders' do
    render
    children.each do |child|
      expect(rendered)
        .to have_css "img[src='#{view.asset_path(child.icon)}']"
    end
  end

  it 'does not link to files' do
    render
    children.each do |child|
      expect(rendered).not_to have_link(child.name)
    end
  end

  context 'when children are folders' do
    before do
      children.each do |child|
        allow(child).to receive(:folder?).and_return true
      end
    end

    it 'renders the links to folder' do
      render
      children.each do |child|
        expect(rendered).to have_link(
          child.name,
          href: profile_project_revision_folder_path(
            project.owner, project.slug, revision.id,
            VCS::File.id_to_hashid(child.file_id)
          )
        )
      end
    end
  end

  context 'when children have backups' do
    before do
      children.each do |child|
        association = child.association(:backup)
        association.target =
          build_stubbed(:vcs_file_backup, file_version: child)
      end
    end

    it 'renders the links of file backups' do
      render
      children.each do |child|
        link = child.backup.link_to_remote
        expect(rendered).to have_css "a[href='#{link}'][target='_blank']"
      end
    end
  end

  it 'renders a link to infos for each file' do
    render
    children.each do |child|
      link = profile_project_file_infos_path(
        project.owner,
        project,
        VCS::File.id_to_hashid(child.file_id)
      )
      expect(rendered).to have_link(text: '', href: link)
    end
  end

  context 'when action name is show' do
    let(:action)      { 'show' }
    let(:ancestors)   { [parent, grandparent] }
    let(:grandparent) { build_stubbed :vcs_version, name: 'Docs' }
    let(:parent)      { build_stubbed :vcs_version, name: 'Other' }
    let(:folder)      { build_stubbed :vcs_version, name: 'Folder' }

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
      [grandparent, parent, folder].each do |ancestor|
        render
        expect(rendered).to have_link(
          ancestor.name,
          href: profile_project_revision_folder_path(
            project.owner,
            project.slug,
            revision,
            VCS::File.id_to_hashid(ancestor.file_id)
          )
        )
      end
    end

    it 'renders link to home-folder breadcrumb' do
      render
      expect(rendered).to have_link(
        '',
        href: profile_project_revision_root_folder_path(project.owner, project,
                                                        revision)
      )
    end
  end
end
