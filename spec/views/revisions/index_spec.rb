# frozen_string_literal: true

RSpec.describe 'revisions/index', type: :view do
  let(:project)     { create(:project) }
  let(:repository)  { project.repository }
  let(:revisions)   { [revision1, revision2, revision3] }
  let(:revision1) do
    create :git_revision, repository: repository, author: authors[0]
  end
  let(:revision2) do
    create :git_revision, repository: repository, author: authors[1]
  end
  let(:revision3) do
    create :git_revision, repository: repository, author: authors[2]
  end
  let(:authors) { create_list :user, 3 }

  before do
    assign(:project, project)
    assign(:revisions, revisions)
    controller.request.path_parameters[:profile_handle] = project.owner.to_param
    controller.request.path_parameters[:project_slug] = project.to_param
  end

  it 'renders the title of each revision' do
    render
    revisions.each do |revision|
      expect(rendered).to have_css(
        ".revision[id='#{revision.id}'] .title",
        text: revision.title
      )
    end
  end

  it 'renders the summary of each revision' do
    render
    revisions.each do |revision|
      expect(rendered).to have_css(
        ".revision[id='#{revision.id}'] .summary",
        text: revision.summary
      )
    end
  end

  it 'renders the author of each revision with link' do
    render
    authors.each do |author|
      expect(rendered).to have_css '.revision .profile', text: author.name
      expect(rendered).to have_link author.name, href: profile_path(author)
    end
  end

  it 'renders a timestamp with link for each revision' do
    render
    revisions.each do |revision|
      expect(rendered).to have_link(
        time_ago_in_words(revision.created_at),
        href: profile_project_revisions_path(project.owner, project,
                                             anchor: revision.id)
      )
    end
  end

  it 'renders that no files changed' do
    render
    revisions.each do |revision|
      expect(rendered).to have_css(
        ".revision[id='#{revision.id}'] .revision-diff",
        text: 'No files changed.'
      )
    end
  end

  context 'when file diffs exist' do
    let(:revisions)   { nil }
    let!(:root)       { create :file, :root, repository: project.repository }
    let!(:file1)      { create :file, name: 'File1', parent: root }
    let!(:folder)     { create :file, :folder, name: 'Folder', parent: root }
    let!(:revision1)  { create :git_revision, repository: project.repository }
    let!(:file2)      { create :file, name: 'File2', parent: root }
    before            { file1.update(parent_id: folder.id) }
    let!(:revision2)  { create :git_revision, repository: project.repository }
    before            { file2.destroy }
    before            { file1.update(modified_time: Time.zone.now) }
    let!(:revision3)  { create :git_revision, repository: project.repository }

    before { assign(:revisions, [revision3, revision2, revision1]) }

    it 'renders a link to infos for each file' do
      render
      [file1, folder, file2].each do |file|
        link = profile_project_file_infos_path(project.owner, project, file.id)
        expect(rendered).to have_link(text: 'More', href: link)
      end
    end

    context 'under revision 1' do
      it 'it lists file1 as added' do
        render
        expect(rendered).to have_css(
          ".revision[id='#{revision1.id}'] .file.added",
          text: 'File1 added to Home'
        )
      end
      it 'it lists folder as added' do
        render
        expect(rendered).to have_css(
          ".revision[id='#{revision1.id}'] .file.added",
          text: 'Folder added to Home'
        )
      end
    end

    context 'under revision 2' do
      it 'it lists file2 as added' do
        render
        expect(rendered).to have_css(
          ".revision[id='#{revision2.id}'] .file.added",
          text: 'File2 added to Home'
        )
      end
      it 'it lists file1 as moved' do
        render
        expect(rendered).to have_css(
          ".revision[id='#{revision2.id}'] .file.moved",
          text: 'File1 moved to Home > Folder'
        )
      end
    end

    context 'under revision 3' do
      it 'it lists file2 as deleted' do
        render
        expect(rendered).to have_css(
          ".revision[id='#{revision3.id}'] .file.deleted",
          text: 'File2 deleted from Home'
        )
      end
      it 'it lists file1 as modified' do
        render
        expect(rendered).to have_css(
          ".revision[id='#{revision3.id}'] .file.modified",
          text: 'File1 modified'
        )
      end
    end
  end
end
