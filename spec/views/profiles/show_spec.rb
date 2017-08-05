# frozen_string_literal: true

RSpec.describe 'profiles/show', type: :view do
  let(:profile) { build(:user) }

  before { assign(:profile, profile) }

  it 'renders the name of the profile' do
    render
    expect(rendered).to have_text profile.name
  end
end
