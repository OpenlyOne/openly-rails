# frozen_string_literal: true

RSpec.describe 'projects/edit', type: :view do
  let(:project) { build_stubbed(:project) }

  before { assign(:project, project) }

  it 'renders a form with project_path action' do
    render
    expect(rendered).to have_css(
      'form'\
      "[action='#{profile_project_path(project.owner, project)}']"\
      "[method='post']"
    )
  end

  it 'renders errors' do
    project.errors.add(:base, 'mock error')
    render
    expect(rendered).to have_css '.validation-errors', text: 'mock error'
  end

  it 'has an input field for title' do
    render
    expect(rendered).to have_css 'input#project_title'
  end

  it 'has an input field for slug' do
    render
    expect(rendered).to have_css 'input#project_slug'
  end

  it 'has a button to save the project' do
    render
    expect(rendered).to have_css "button[action='submit']", text: 'Save'
  end
end
