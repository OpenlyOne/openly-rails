# frozen_string_literal: true

RSpec.describe 'file_infos/index', type: :view do
  let(:project)           { build_stubbed :project }
  let(:file)              { build :file, name: 'My Document' }
  let(:current_file_diff) { VersionControl::FileDiff.new(nil, file, file) }
  let(:file_versions)     { [] }

  before do
    assign(:project, project)
    assign(:file, file)
    assign(:current_file_diff, current_file_diff)
    assign(:file_versions, file_versions)
  end

  it 'renders the file icon' do
    render
    icon = view.icon_for_file(file)
    expect(rendered).to have_css "h2 img[src='#{view.asset_path(icon)}']"
  end

  it 'renders the file name' do
    render
    expect(rendered).to have_css 'h2', text: file.name
  end

  it 'has a link to the file on Google Drive' do
    render
    expect(rendered).to have_link 'Open in Drive',
                                  href: view.external_link_for_file(file)
  end

  it 'has a link to the parent folder' do
    render
    link = profile_project_folder_path(project.owner, project, file.parent_id)
    expect(rendered).to have_link 'Open Parent Folder', href: link
  end

  it 'renders that the file has been unchanged since the last revision' do
    render
    expect(rendered).to have_text 'New Changes (uncommitted)'
    expect(rendered).to have_text(
      'No changes have been made to this file since the last revision'
    )
  end

  it 'renders that there are no previous versions of the file' do
    render
    expect(rendered).to have_text 'No previous versions of this file exist.'
  end

  context 'when file is and has been deleted' do
    let(:current_file_diff) { nil }

    it 'renders that the file has been deleted from the project' do
      render
      expect(rendered)
        .to have_text "This file has been deleted from #{project.title}."
    end

    it 'does not have a link to the file on Google Drive' do
      render
      expect(rendered).not_to have_link 'Open in Drive'
    end

    it 'does not have a link to the parent folder' do
      render
      expect(rendered).not_to have_link 'Open Parent Folder'
    end
  end

  context 'when current_file_diff has uncommitted changes' do
    before do
      allow(current_file_diff).to receive(:changes)
        .and_return %i[added modified moved deleted]
      allow(current_file_diff).to receive(:ancestors_of_file).and_return []
    end

    it 'renders uncommitted changes' do
      render
      expect(rendered).to have_text 'My Document added to Home'
      expect(rendered).to have_text 'My Document modified'
      expect(rendered).to have_text 'My Document moved to Home'
      expect(rendered).to have_text 'My Document deleted from Home'
    end
  end

  context 'when file has past versions' do
    let(:file_versions) { [diff3, diff2, diff1] }
    let(:diff1) { VersionControl::FileDiff.new(revision_diff1, file, file) }
    let(:diff2) { VersionControl::FileDiff.new(revision_diff2, file, file) }
    let(:diff3) { VersionControl::FileDiff.new(revision_diff3, file, file) }
    let(:revision_diff1)  { instance_double VersionControl::RevisionDiff }
    let(:revision_diff2)  { instance_double VersionControl::RevisionDiff }
    let(:revision_diff3)  { instance_double VersionControl::RevisionDiff }
    let(:revisions)       { [revision1, revision2, revision3] }
    let(:revision1)       { create :git_revision, repository: repository }
    let(:revision2)       { create :git_revision, repository: repository }
    let(:revision3)       { create :git_revision, repository: repository }
    let(:repository)      { build :repository }
    let(:file)            { build :file, name: 'File' }
    let(:ancestors)       { [] }

    before do
      allow(revision_diff1).to receive(:base).and_return revision1
      allow(revision_diff2).to receive(:base).and_return revision2
      allow(revision_diff3).to receive(:base).and_return revision3

      allow(diff1).to receive(:changes).and_return([:added])
      allow(diff2).to receive(:changes).and_return(%i[moved modified])
      allow(diff3).to receive(:changes).and_return([:deleted])

      allow(diff1).to receive(:ancestors_of_file).and_return ancestors
      allow(diff2).to receive(:ancestors_of_file).and_return ancestors
      allow(diff3).to receive(:ancestors_of_file).and_return ancestors
    end

    it 'renders the title of each revision' do
      render
      revisions.each do |revision|
        expect(rendered).to have_text revision.title
      end
    end

    it 'renders the summary of each revision' do
      render
      revisions.each do |revision|
        expect(rendered).to have_text revision.summary
      end
    end

    it 'renders the timestamp with link for each revision' do
      render
      revisions.each do |revision|
        expect(rendered).to have_link(
          time_ago_in_words(revision.created_at),
          href: profile_project_revisions_path(project.owner, project,
                                               anchor: revision.id)
        )
      end
    end

    it 'renders the file change of each revision' do
      render
      expect(rendered).to have_css(
        ".revision[id='#{revision1.id}'] .file.added",
        text: 'File added to Home'
      )
      expect(rendered).to have_css(
        ".revision[id='#{revision2.id}'] .file.modified",
        text: 'File modified'
      )
      expect(rendered).to have_css(
        ".revision[id='#{revision2.id}'] .file.moved",
        text: 'File moved to Home'
      )
      expect(rendered).to have_css(
        ".revision[id='#{revision3.id}'] .file.deleted",
        text: 'File deleted from Home'
      )
    end
  end
end
