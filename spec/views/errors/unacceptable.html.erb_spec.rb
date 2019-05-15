# frozen_string_literal: true

RSpec.describe 'errors/unacceptable', type: :view do
  it 'tells the user that the request was rejected' do
    render
    expect(rendered).to have_text 'request was rejected'
  end

  it 'provides a contact email address' do
    render
    expect(rendered).to have_selector('a', text: 'hello@open.ly')
  end
end
