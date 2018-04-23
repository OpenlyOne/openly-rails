# frozen_string_literal: true

RSpec.describe 'errors/internal_server_error', type: :view do
  it 'tells the user an internal server error occurred' do
    render
    expect(rendered).to have_text 'internal server error'
  end

  it 'provides a contact email address' do
    render
    expect(rendered).to have_selector('a', text: 'hello@openly.one')
  end
end
