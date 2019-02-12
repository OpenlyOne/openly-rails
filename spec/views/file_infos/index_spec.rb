# frozen_string_literal: true

require 'views/shared_examples/showing_content_changes.rb'

RSpec.describe 'file_infos/index', type: :view do
  let(:project)               { build_stubbed :project }
  let(:master_branch)         { build_stubbed :vcs_branch }
  let(:file)                  { build_stubbed :vcs_version }
  let(:file_in_branch)        { build_stubbed :vcs_file_in_branch }
  let(:parent_in_branch)      { nil }
  let(:uncaptured_file_diff)  { nil }
  let(:committed_file_diffs)  { [] }

  let(:locals) do
    {
      path_parameters:  [project.owner, project],
      file_change_path: 'profile_project_file_change_path',
      folder_path:      'profile_project_folder_path',
      force_syncs_path: 'profile_project_force_syncs_path',
      root_folder_path: 'profile_project_root_folder_path'
    }
  end

  before do
    allow(project).to receive(:master_branch).and_return master_branch
    assign(:project, project)
    assign(:master_branch, project.master_branch)
    assign(:file, file)
    assign(:file_in_branch, file_in_branch)
    assign(:parent_in_branch, parent_in_branch)
    assign(:uncaptured_file_diff, uncaptured_file_diff)
    assign(:committed_file_diffs, committed_file_diffs)
  end

  # Overwrite the render method to include locals
  def render
    super(template: self.class.top_level_description, locals: locals)
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

  context 'when current user can view files in branches' do
    before { assign(:user_can_view_file_in_branch, true) }

    it 'renders that the file has been deleted from the project' do
      render
      expect(rendered)
        .to have_text "This file has been deleted from #{project.title}."
    end
  end

  context 'when uncaptured file diff is present' do
    let(:uncaptured_file_diff) do
      build_stubbed :vcs_file_diff,
                    new_version: version, old_version: version
    end
    let(:version) { build_stubbed :vcs_version, name: 'My Document' }
    let(:parent_in_branch) { build_stubbed :vcs_file_in_branch, :folder }

    it 'does not have a link to the file on Google Drive' do
      render
      expect(rendered).not_to have_link 'Open in Drive'
    end

    it 'does not have a link to the parent folder' do
      render
      expect(rendered).not_to have_link 'Open Parent Folder'
    end

    it 'does not have a button to force sync the file' do
      render
      sync_path =
        profile_project_force_syncs_path(
          project.owner,
          project,
          VCS::File.id_to_hashid(uncaptured_file_diff.file_id)
        )
      expect(rendered).not_to have_css(
        'form'\
        "[action='#{sync_path}']"\
        "[method='post']"
      )
    end

    context 'when current user can view files in branches' do
      before { assign(:user_can_view_file_in_branch, true) }

      it 'has a link to the file on Google Drive' do
        render
        expect(rendered).to have_link 'Open in Drive',
                                      href: file_in_branch.link_to_remote
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
                                           parent_in_branch.hashed_file_id)
        expect(rendered).to have_link 'Open Parent Folder', href: link
      end

      context 'when remote_file_id of file is nil' do
        before { file_in_branch.remote_file_id = nil }

        it 'does not have a link to the file on Google Drive' do
          render
          expect(rendered).not_to have_link 'Open in Drive'
        end
      end

      context 'when parent is root folder' do
        let(:parent_in_branch) { build_stubbed :vcs_file_in_branch, :root }

        it 'has a link to the root folder' do
          render
          link = profile_project_root_folder_path(project.owner, project)
          expect(rendered).to have_link 'Open Home Folder', href: link
        end
      end

      context 'when uncaptured file diff has changes' do
        before do
          allow(uncaptured_file_diff).to receive(:change_types)
            .and_return %i[addition modification movement rename deletion]
          allow(uncaptured_file_diff)
            .to receive(:ancestor_path).and_return 'Home'
        end

        it 'renders uncaptured changes' do
          render
          expect(rendered).to have_text 'My Document added to Home'
          expect(rendered).to have_text(
            'My Document renamed from ' \
            "'#{uncaptured_file_diff.previous_name}' in Home"
          )
          expect(rendered).to have_text 'My Document modified in Home'
          expect(rendered).to have_text 'My Document moved to Home'
          expect(rendered).to have_text 'My Document deleted from Home'
        end

        it_should_behave_like 'showing content changes' do
          let(:diff) { uncaptured_file_diff }
          let(:link_to_side_by_side) do
            profile_project_file_change_path(
              project.owner, project, diff.hashed_file_id
            )
          end
        end

        context 'when current user can force sync files in project' do
          before { assign(:user_can_force_sync_files, true) }

          it 'has a button to force sync the file' do
            render
            sync_path =
              profile_project_force_syncs_path(
                project.owner,
                project,
                VCS::File.id_to_hashid(uncaptured_file_diff.file_id)
              )
            expect(rendered).to have_css(
              'form'\
              "[action='#{sync_path}']"\
              "[method='post']",
              text: 'Force Sync'
            )
          end

          context 'when remote_file_id of file is nil' do
            before { file_in_branch.remote_file_id = nil }

            it 'does not have a button to force sync the file' do
              render
              sync_path =
                profile_project_force_syncs_path(
                  project.owner,
                  project,
                  VCS::File.id_to_hashid(uncaptured_file_diff.file_id)
                )
              expect(rendered).not_to have_css(
                'form'\
                "[action='#{sync_path}']"\
                "[method='post']"
              )
            end
          end
        end
      end
    end
  end

  context 'when file has past versions' do
    let(:revisions) { committed_file_diffs.map(&:commit) }
    let(:committed_file_diffs) do
      [(build_stubbed :vcs_file_diff, new_version: s1, commit: r1),
       (build_stubbed :vcs_file_diff, new_version: s2, commit: r2),
       (build_stubbed :vcs_file_diff, new_version: s3, commit: r3)]
    end
    let(:r1)  { build_stubbed :vcs_commit }
    let(:r2)  { build_stubbed :vcs_commit }
    let(:r3)  { build_stubbed :vcs_commit }
    let(:s1) do
      build_stubbed :vcs_version, :with_backup, name: 'f1'
    end
    let(:s2) do
      build_stubbed :vcs_version, :with_backup, name: 'f2'
    end
    let(:s3) do
      build_stubbed :vcs_version, :with_backup, name: 'f3'
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
        link = diff.current_version.backup.link_to_remote
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

    it_should_behave_like 'showing content changes' do
      let(:diff) { committed_file_diffs.first }
      let(:link_to_side_by_side) do
        profile_project_revision_file_change_path(
          project.owner, project, r1, diff.hashed_file_id
        )
      end
    end

    context 'when diff is restorable' do
      before do
        allow(view)
          .to receive(:restorable?)
          .with(committed_file_diffs.first, master_branch)
          .and_return true
      end

      it 'does not have restore action' do
        render
        expect(rendered).not_to have_text('Restore')
      end

      context 'when current user can restore files' do
        before { assign(:user_can_restore_files, true) }

        it 'has restore action for diff 1' do
          render
          restore_action = profile_project_file_restores_path(
            project.owner, project, committed_file_diffs.first.new_version
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
end
