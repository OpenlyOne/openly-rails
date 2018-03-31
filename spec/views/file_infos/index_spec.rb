# frozen_string_literal: true

RSpec.describe 'file_infos/index', type: :view do
  let(:project)               { build_stubbed :project }
  let(:file)                  { build_stubbed :file_resource_snapshot }
  let(:staged_file_diff)      { nil }
  let(:committed_file_diffs)  { [] }

  before do
    assign(:project, project)
    assign(:file, file)
    assign(:staged_file_diff, staged_file_diff)
    assign(:committed_file_diffs, committed_file_diffs)
  end

  it 'renders the file icon' do
    render
    expect(rendered).to have_css "h2 img[src='#{view.asset_path(file.icon)}']"
  end

  it 'renders the file name' do
    render
    expect(rendered).to have_css 'h2', text: file.name
  end

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

  it 'renders that there are no previous versions of the file' do
    render
    expect(rendered).to have_text 'No previous versions of this file exist.'
  end

  context 'when staged file diff is present' do
    let(:staged_file_diff) do
      Stage::FileDiff.new(project: project, staged_snapshot: snapshot,
                          committed_snapshot: snapshot)
    end
    let(:snapshot) do
      build_stubbed :file_resource_snapshot, name: 'My Document', parent: parent
    end
    let(:parent)    { build_stubbed :file_resource }
    let(:root)      { build_stubbed :file_resource }

    before { allow(project).to receive(:root_folder).and_return root }

    it 'has a link to the file on Google Drive' do
      render
      expect(rendered).to have_link 'Open in Drive',
                                    href: staged_file_diff.external_link
    end

    it 'renders that the file has been unchanged since the last revision' do
      render
      expect(rendered).to have_text 'New Changes (since last revision)'
      expect(rendered).to have_text(
        'No changes have been made to this file since the last revision'
      )
    end

    it 'has a link to the parent folder' do
      render
      link = profile_project_folder_path(project.owner, project,
                                         staged_file_diff
                                         .current_or_previous_snapshot
                                         .parent.external_id)
      expect(rendered).to have_link 'Open Parent Folder', href: link
    end

    it 'does not have a button to force sync the file' do
      render
      sync_path =
        profile_project_force_syncs_path(project.owner, project,
                                         staged_file_diff.external_id)
      expect(rendered).not_to have_css(
        'form'\
        "[action='#{sync_path}']"\
        "[method='post']"
      )
    end

    context 'when parent is root folder' do
      let(:parent) { root }

      it 'has a link to the root folder' do
        render
        link = profile_project_root_folder_path(project.owner, project)
        expect(rendered).to have_link 'Open Home Folder', href: link
      end
    end

    context 'when staged file diff has uncaptured changes' do
      before do
        allow(staged_file_diff).to receive(:changes_as_symbols)
          .and_return %i[added modified moved renamed deleted]
        allow(staged_file_diff).to receive(:ancestor_path).and_return 'Home'
      end

      it 'renders uncaptured changes' do
        render
        expect(rendered).to have_text 'My Document added to Home'
        expect(rendered).to have_text(
          "My Document renamed from '#{staged_file_diff.previous_name}' in Home"
        )
        expect(rendered).to have_text 'My Document modified in Home'
        expect(rendered).to have_text 'My Document moved to Home'
        expect(rendered).to have_text 'My Document deleted from Home'
      end
    end

    context 'when current user can force sync files in project' do
      before { assign(:user_can_force_sync_files, true) }

      it 'has a button to force sync the file' do
        render
        sync_path =
          profile_project_force_syncs_path(project.owner, project,
                                           staged_file_diff.external_id)
        expect(rendered).to have_css(
          'form'\
          "[action='#{sync_path}']"\
          "[method='post']",
          text: 'Force Sync'
        )
      end
    end
  end

  context 'when file has past versions' do
    let(:revisions) { committed_file_diffs.map(&:revision) }
    let(:committed_file_diffs) do
      [(build_stubbed :file_diff, current_snapshot: s1, revision: r1),
       (build_stubbed :file_diff, current_snapshot: s2, revision: r2),
       (build_stubbed :file_diff, current_snapshot: s3, revision: r3)]
    end
    let(:r1)  { build_stubbed :revision }
    let(:r2)  { build_stubbed :revision }
    let(:r3)  { build_stubbed :revision }
    let(:s1)  { build_stubbed :file_resource_snapshot, name: 'f1' }
    let(:s2)  { build_stubbed :file_resource_snapshot, name: 'f2' }
    let(:s3)  { build_stubbed :file_resource_snapshot, name: 'f3' }

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
        ".revision[id='#{r1.id}'] .file.added",
        text: 'f1 added'
      )
      expect(rendered).to have_css(
        ".revision[id='#{r2.id}'] .file.added",
        text: 'f2 added'
      )
      expect(rendered).to have_css(
        ".revision[id='#{r3.id}'] .file.added",
        text: 'f3 added'
      )
    end
  end
end
