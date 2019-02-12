# frozen_string_literal: true

RSpec.describe 'projects/new', type: :view do
  let(:project) { build(:project, is_public: nil) }

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

  it 'has a select option for visibility' do
    render
    expect(rendered).to have_field(
      class: 'public', type: 'radio', with: true, checked: false
    )
    expect(rendered).to have_field(
      class: 'private', type: 'radio', with: false, checked: false
    )
  end

  xit 'has the private option disabled' do
    expect(rendered).to have_field('Private', type: 'select', disabled: true)
  end

  it 'has a button to create the project' do
    render
    expect(rendered)
      .to have_css "button[action='submit']", text: 'Create'
  end

  xcontext 'when user can create private projects' do
    before { assign(:user_can_create_private_projects, true) }

    it 'has the private option enabled' do
      render
      expect(rendered).to have_field('Private', type: 'select', disabled: false)
    end
  end
end
