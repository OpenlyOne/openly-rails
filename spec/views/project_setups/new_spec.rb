# frozen_string_literal: true

RSpec.describe 'project_setups/new', type: :view do
  let(:setup)   { build_stubbed(:project_setup) }
  let(:project) { setup.project }

  before { assign(:project, project) }
  before { assign(:setup, setup) }

  it 'renders a form with profile_project_setup_path action' do
    render
    expect(rendered).to have_css(
      'form'\
      "[action='#{profile_project_setup_path(project.owner, project)}']"\
      "[method='post']"
    )
  end

  it 'renders errors' do
    setup.errors.add(:base, 'mock error')
    render
    expect(rendered).to have_css '.validation-errors', text: 'mock error'
  end

  it 'has an input field for link to Google Drive folder' do
    render
    expect(rendered).to have_css 'input#project_setup_link'
  end

  it 'has a button to import the folder' do
    render
    expect(rendered)
      .to have_css "button[action='submit']", text: 'Import'
  end
end
