# frozen_string_literal: true

RSpec.describe 'revisions/index', type: :view do
  let(:project)     { build_stubbed :project }
  let(:revisions)   { build_stubbed_list :revision, 3, :published }

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
    revisions.map(&:author).each do |author|
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

  it 'renders a link to time travel back to that revision' do
    render
    revisions.each do |revision|
      expect(rendered).to have_link(
        revision.title,
        href: profile_project_revision_root_folder_path(project.owner, project,
                                                        revision)
      )
    end
  end

  context 'when file diffs exist' do
    let(:diffs) do
      snapshots.map do |snapshot|
        FileDiff.new(file_resource_id: 12,
                     current_snapshot: snapshot,
                     first_three_ancestors: ancestors)
      end
    end
    let(:snapshots) do
      build_stubbed_list(:file_resource_snapshot, 3, :with_backup)
    end

    let(:ancestors) { [] }

    before do
      root = instance_double FileResource
      allow(project).to receive(:root_folder).and_return root
      allow(root).to receive(:provider).and_return Providers::GoogleDrive
      allow(revisions.first).to receive(:file_diffs).and_return diffs
    end

    it 'renders a link to each file backup' do
      render
      diffs.each do |diff|
        link = diff.current_snapshot.backup.file_resource.external_link
        expect(rendered).to have_link(text: diff.name, href: link)
      end
    end

    it 'renders a link to each folder' do
      diffs.each do |diff|
        allow(diff.current_or_previous_snapshot)
          .to receive(:folder?).and_return true
      end

      render
      diffs.each do |diff|
        link = profile_project_revision_folder_path(
          project.owner, project.slug, revisions.first.id, diff.external_id
        )
        expect(rendered).to have_link(text: diff.name, href: link)
      end
    end

    it 'renders a link to infos for each file' do
      render
      diffs.each do |diff|
        link = profile_project_file_infos_path(project.owner,
                                               project,
                                               diff.external_id)
        expect(rendered).to have_link(text: 'More', href: link)
      end
    end

    it 'it lists files as added' do
      render
      diffs.each do |diff|
        expect(rendered).to have_css(
          ".revision[id='#{revisions.first.id}'] .file.addition",
          text: "#{diff.name} added"
        )
      end
    end
  end
end
