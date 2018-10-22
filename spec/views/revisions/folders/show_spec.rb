# frozen_string_literal: true

RSpec.describe 'revisions/folders/show', type: :view do
  let(:folder)    { nil }
  let(:project)   { build_stubbed :project }
  let(:revision)  { build_stubbed :revision, :published, project: project }
  let(:children)  { build_stubbed_list :committed_file, 5, revision: revision }
  let(:snapshots) { children.map(&:file_resource_snapshot) }

  before do
    assign(:project,  project)
    assign(:revision, revision)
    assign(:children, children)
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
    snapshots.each do |snapshot|
      expect(rendered).to have_text snapshot.name
    end
  end

  it 'renders the thumbnails of files and folders' do
    thumbnail = create :file_resource_thumbnail
    snapshots.each do |snapshot|
      allow(snapshot)
        .to receive(:thumbnail).and_return thumbnail
    end

    render

    snapshots.each do |snapshot|
      expect(rendered).to have_css "img[src='#{snapshot.thumbnail_image.url}']"
    end
  end

  it 'renders the icons of files and folders' do
    render
    snapshots.each do |snapshot|
      expect(rendered)
        .to have_css "img[src='#{view.asset_path(snapshot.icon)}']"
    end
  end

  it 'does not link to files' do
    render
    snapshots.each do |snapshot|
      expect(rendered).not_to have_link(snapshot.name)
    end
  end

  context 'when snapshots are folders' do
    before do
      snapshots.each do |snapshot|
        allow(snapshot).to receive(:folder?).and_return true
      end
    end

    it 'renders the links to folder' do
      render
      snapshots.each do |snapshot|
        expect(rendered).to have_link(
          snapshot.name,
          href: profile_project_revision_folder_path(
            project.owner, project.slug, revision.id, snapshot.external_id
          )
        )
      end
    end
  end

  context 'when snapshots have backups' do
    before do
      snapshots.each do |snapshot|
        association = snapshot.association(:backup)
        association.target =
          build_stubbed(:file_resource_backup, file_resource_snapshot: snapshot)
      end
    end

    it 'renders the links of file backups' do
      render
      snapshots.each do |snapshot|
        link = snapshot.backup.file_resource.external_link
        expect(rendered).to have_css "a[href='#{link}'][target='_blank']"
      end
    end
  end

  it 'renders a link to infos for each file' do
    render
    snapshots.each do |snapshot|
      link = profile_project_file_infos_path(project.owner,
                                             project,
                                             snapshot.external_id)
      expect(rendered).to have_link(text: '', href: link)
    end
  end
end
