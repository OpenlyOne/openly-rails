# frozen_string_literal: true

RSpec.describe 'projects/new', type: :view do
  let(:project) { build(:project) }

  before { assign(:project, project) }

  it 'renders a form with projects_path action' do
    render
    expect(rendered).to have_css(
      'form'\
      "[action='#{projects_path}']"\
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

  it 'has a button to create the project' do
    render
    expect(rendered)
      .to have_css "button[action='submit']", text: 'Create'
  end
end
