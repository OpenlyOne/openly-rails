# frozen_string_literal: true

require 'views/shared_examples/showing_content_changes.rb'

RSpec.describe 'revisions/new', type: :view do
  let(:project)       { build_stubbed :project, :with_repository }
  let(:repository)    { project.repository }
  let(:master_branch) { build_stubbed :vcs_branch, repository: repository }
  let(:revision)      { build_stubbed :vcs_commit, branch: master_branch }
  let(:file_diffs)    { [] }

  before { allow(revision).to receive(:file_diffs).and_return(file_diffs) }

  before do
    assign(:project, project)
    assign(:master_branch, master_branch)
    assign(:revision, revision)
    controller.request.path_parameters[:profile_handle] = project.owner.to_param
    controller.request.path_parameters[:project_slug] = project.to_param
  end

  it 'renders a form with profile_project_revision_path action' do
    render
    expect(rendered).to have_css(
      'form'\
      "[action='#{profile_project_revisions_path(project.owner, project)}']"\
      "[method='post']"
    )
  end

  it 'renders errors' do
    revision.errors.add(:base, 'mock error')
    render
    expect(rendered).to have_css '.validation-errors', text: 'mock error'
  end

  it 'has a hidden field for revision id' do
    render
    expect(rendered).to have_css(
      "input#revision_id[value='#{revision.id}']",
      visible: false
    )
  end

  it 'has a text field for revision title' do
    render
    expect(rendered).to have_css 'input#revision_title'
  end

  it 'has a text area for revision summary' do
    render
    expect(rendered).to have_css 'textarea#revision_summary'
  end

  it 'has a button to capture changes' do
    render
    expect(rendered)
      .to have_css "button[action='submit']", text: 'Capture Changes'
  end

  it 'lets the user know that there are no changes to review' do
    render
    expect(rendered).to have_text 'No files changed.'
  end

  context 'when file diffs exist' do
    let(:file_diffs) do
      versions.map do |version|
        VCS::FileDiff.new(new_version: version, first_three_ancestors: [])
      end
    end
    let(:versions) do
      build_stubbed_list(:vcs_version, 3, :with_backup)
    end

    before do
      root = instance_double VCS::FileInBranch
      allow(master_branch).to receive(:root).and_return root
      allow(root).to receive(:provider).and_return Providers::GoogleDrive
      file_diffs.first.changes.each(&:unselect!)
    end

    it 'has a checkbox for every change' do
      render
      file_diffs.flat_map(&:changes).each do |change|
        expect(rendered)
          .to have_field(with: change.id, checked: change.selected?)
      end
    end

    it 'it lists files as added' do
      render
      file_diffs.each do |diff|
        expect(rendered)
          .to have_css('.file.addition', text: "#{diff.name} added")
      end
    end

    it 'renders a link to each file backup' do
      render
      file_diffs.each do |diff|
        link = diff.current_version.backup.link_to_remote
        expect(rendered).to have_link(text: diff.name, href: link)
      end
    end

    it 'marks all links as remote links' do
      render
      expect(rendered).to have_css("a[target='_blank']")
      expect(rendered).not_to have_css("a:not([target='_blank'])")
    end

    it_should_behave_like 'showing content changes', link_in_new_tab: true do
      let(:diff) { revision.file_changes.first }
      let(:link_to_side_by_side) do
        profile_project_file_change_path(
          project.owner, project, diff.hashed_file_id
        )
      end
    end
  end
end
