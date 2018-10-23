# frozen_string_literal: true

RSpec.describe 'revisions/folders/show', type: :view do
  let(:folder)    { nil }
  let(:project)   { build_stubbed :project }
  let(:revision)  { build_stubbed :revision, :published, project: project }
  let(:children)  { build_stubbed_list :file_resource_snapshot, 5 }
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

  it 'renders revision metadata' do
    render
    expect(rendered).to have_text(revision.title)
    expect(rendered).to have_text(revision.author.name)
    expect(rendered)
      .to have_text("#{time_ago_in_words(revision.created_at)} ago")
  end

  it 'renders the names of files and folders' do
    render
    children.each do |child|
      expect(rendered).to have_text child.name
    end
  end

  it 'renders the thumbnails of files and folders' do
    thumbnail = create :file_resource_thumbnail
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
            project.owner, project.slug, revision.id, child.external_id
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
          build_stubbed(:file_resource_backup, file_resource_snapshot: child)
      end
    end

    it 'renders the links of file backups' do
      render
      children.each do |child|
        link = child.backup.file_resource.external_link
        expect(rendered).to have_css "a[href='#{link}'][target='_blank']"
      end
    end
  end

  it 'renders a link to infos for each file' do
    render
    children.each do |child|
      link = profile_project_file_infos_path(project.owner,
                                             project,
                                             child.external_id)
      expect(rendered).to have_link(text: '', href: link)
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
        '',
        href: profile_project_revision_root_folder_path(project.owner, project,
                                                        revision)
      )
    end
  end
end
