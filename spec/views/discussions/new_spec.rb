# frozen_string_literal: true

RSpec.describe 'discussions/new', type: :view do
  let(:discussion)  { build(:discussions_suggestion) }
  let(:project)     { discussion.project }

  before do
    assign(:project, project)
    assign(:discussion, discussion)
  end

  it 'renders a form with profile_project_discussions_path action' do
    create_path =
      profile_project_discussions_path(project.owner, project, 'suggestions')
    render
    expect(rendered).to have_css(
      'form'\
      "[action='#{create_path}']"\
      "[method='post']"
    )
  end

  it 'renders errors' do
    discussion.errors.add(:base, 'mock error')
    render
    expect(rendered).to have_css '.validation-errors', text: 'mock error'
  end

  it 'has an input field for title' do
    render
    expect(rendered).to have_css 'input#discussions_suggestion_title'
  end

  it 'has a button to create the discussion' do
    render
    expect(rendered).to have_css "button[action='submit']", text: 'Create'
  end
end
