# frozen_string_literal: true

RSpec.describe 'projects/new', type: :view do
  let(:project) { build(:project, is_public: nil) }

  before { assign(:project, project) }
  before { assign(:current_account, create(:account)) }

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
      class: 'private', type: 'radio',
      with: false, checked: false, disabled: true
    )
  end

  it 'has the private option disabled' do
    render
    expect(rendered).to have_field(
      class: 'private', type: 'radio', disabled: true
    )
  end

  it 'renders an upgrade button' do
    render
    expect(rendered).to have_css(
      "a[href^='mailto:#{Settings.support_email}']", text: 'Upgrade'
    )
  end

  it 'has a button to create the project' do
    render
    expect(rendered)
      .to have_css "button[action='submit']", text: 'Create'
  end

  context 'when user can create private projects' do
    before { assign(:user_can_create_private_projects, true) }

    it 'has the private option enabled' do
      render
      expect(rendered).to have_field(
        class: 'private', type: 'radio', with: false, disabled: false
      )
    end

    it 'does not render an upgrade button' do
      render
      expect(rendered).not_to have_css(
        "a[href^='mailto:#{Settings.support_email}']", text: 'Upgrade'
      )
    end
  end
end
