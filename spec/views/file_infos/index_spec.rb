# frozen_string_literal: true

RSpec.describe 'file_infos/index', type: :view do
  let(:project)               { build_stubbed :project }
  let(:master_branch)         { build_stubbed :vcs_branch }
  let(:file)                  { build_stubbed :vcs_file_snapshot }
  let(:staged_parent)         { nil }
  let(:staged_file_diff)      { nil }
  let(:committed_file_diffs)  { [] }

  before do
    allow(project).to receive(:master_branch).and_return master_branch
    assign(:project, project)
    assign(:master_branch, project.master_branch)
    assign(:file, file)
    assign(:staged_parent, staged_parent)
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
      build_stubbed :vcs_file_diff,
                    new_snapshot: snapshot, old_snapshot: snapshot
    end
    let(:snapshot) { build_stubbed :vcs_file_snapshot, name: 'My Document' }
    let(:staged_parent) { build_stubbed :vcs_staged_file, :folder }

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
                                         staged_parent.remote_file_id)
      expect(rendered).to have_link 'Open Parent Folder', href: link
    end

    it 'does not have a button to force sync the file' do
      render
      sync_path =
        profile_project_force_syncs_path(project.owner, project,
                                         staged_file_diff.remote_file_id)
      expect(rendered).not_to have_css(
        'form'\
        "[action='#{sync_path}']"\
        "[method='post']"
      )
    end

    context 'when parent is root folder' do
      let(:staged_parent) { build_stubbed :vcs_staged_file, :root }

      it 'has a link to the root folder' do
        render
        link = profile_project_root_folder_path(project.owner, project)
        expect(rendered).to have_link 'Open Home Folder', href: link
      end
    end

    context 'when staged file diff has uncaptured changes' do
      before do
        allow(staged_file_diff).to receive(:change_types)
          .and_return %i[addition modification movement rename deletion]
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

      context 'when diff is modification and has content change' do
        let(:content_change) do
          VCS::Operations::ContentDiffer.new(
            new_content: 'hi',
            old_content: 'bye'
          )
        end

        before do
          allow(staged_file_diff).to receive(:modification?).and_return true
          allow(staged_file_diff)
            .to receive(:content_change).and_return content_change
        end

        it 'shows the diff' do
          render
          expect(rendered).to have_css('.fragment.addition', text: 'hi')
          expect(rendered).to have_css('.fragment.deletion', text: 'bye')
        end
      end
    end

    context 'when current user can force sync files in project' do
      before { assign(:user_can_force_sync_files, true) }

      it 'has a button to force sync the file' do
        render
        sync_path =
          profile_project_force_syncs_path(project.owner, project,
                                           staged_file_diff.remote_file_id)
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
    let(:revisions) { committed_file_diffs.map(&:commit) }
    let(:committed_file_diffs) do
      [(build_stubbed :vcs_file_diff, new_snapshot: s1, commit: r1),
       (build_stubbed :vcs_file_diff, new_snapshot: s2, commit: r2),
       (build_stubbed :vcs_file_diff, new_snapshot: s3, commit: r3)]
    end
    let(:r1)  { build_stubbed :vcs_commit }
    let(:r2)  { build_stubbed :vcs_commit }
    let(:r3)  { build_stubbed :vcs_commit }
    let(:s1) do
      build_stubbed :vcs_file_snapshot, :with_backup, name: 'f1'
    end
    let(:s2) do
      build_stubbed :vcs_file_snapshot, :with_backup, name: 'f2'
    end
    let(:s3) do
      build_stubbed :vcs_file_snapshot, :with_backup, name: 'f3'
    end

    before { allow(view).to receive(:restorable?).and_return false }

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

    it 'renders a link to file backup for each revision' do
      render
      committed_file_diffs.each do |diff|
        link = diff.current_snapshot.backup.external_link
        expect(rendered).to have_link(text: diff.name, href: link)
      end
    end

    it 'renders the file change of each revision' do
      render
      expect(rendered).to have_css(
        ".revision[id='#{r1.id}'] .file.addition",
        text: 'f1 added'
      )
      expect(rendered).to have_css(
        ".revision[id='#{r2.id}'] .file.addition",
        text: 'f2 added'
      )
      expect(rendered).to have_css(
        ".revision[id='#{r3.id}'] .file.addition",
        text: 'f3 added'
      )
    end

    context 'when diff is restorable' do
      before do
        allow(view)
          .to receive(:restorable?)
          .with(committed_file_diffs.first, master_branch)
          .and_return true
      end

      it 'has restore action for diff 1' do
        render
        restore_action = profile_project_file_restores_path(
          project.owner, project, committed_file_diffs.first.new_snapshot
        )

        expect(rendered).to have_css(
          'form'\
          "[action='#{restore_action}']"\
          "[method='post']",
          text: 'Restore',
          count: 1
        )
      end
    end
  end
end
