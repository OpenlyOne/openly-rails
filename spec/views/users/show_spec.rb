# frozen_string_literal: true

RSpec.describe 'users/show', type: :view do
  let(:user) { build(:user) }

  before { assign(:user, user) }

  it 'renders the name of the user' do
    render
    expect(rendered).to have_text user.name
  end
end
