# frozen_string_literal: true

RSpec.describe 'profiles/edit', type: :view do
  let(:profile) { build_stubbed(:user) }

  before do
    assign(:profile, profile)
    assign(:projects, [])
  end

  it 'renders a form with profile_path action' do
    render
    expect(rendered).to have_css(
      'form'\
      "[action='#{profile_path(profile)}']"\
      "[method='post']"
    )
  end

  it 'renders errors' do
    profile.errors.add(:base, 'mock error')
    render
    expect(rendered).to have_css '.validation-errors', text: 'mock error'
  end

  it 'has an input field for name' do
    render
    expect(rendered).to have_css 'input#profiles_base_name'
  end

  it 'has a button to save the profile' do
    render
    expect(rendered).to have_css "button[action='submit']", text: 'Save'
  end
end
