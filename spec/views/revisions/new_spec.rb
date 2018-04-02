# frozen_string_literal: true

RSpec.describe 'revisions/new', type: :view do
  let(:project)       { build_stubbed :project }
  let(:revision)      { build_stubbed :revision, project: project }
  let(:file_diffs)    { [] }

  before { allow(revision).to receive(:file_diffs).and_return(file_diffs) }

  before do
    assign(:project, project)
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
      build_stubbed_list(:file_resource_snapshot, 3).map do |snapshot|
        FileDiff.new(file_resource_id: 12,
                     current_snapshot: snapshot,
                     first_three_ancestors: [])
      end
    end

    before do
      root = instance_double FileResource
      allow(project).to receive(:root_folder).and_return root
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

    it 'marks all links as external links' do
      render
      expect(rendered).to have_css("a[target='_blank']")
      expect(rendered).not_to have_css("a:not([target='_blank'])")
    end
  end
end
