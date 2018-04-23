# frozen_string_literal: true

RSpec.describe 'errors/not_found', type: :view do
  it 'tells the user that it could not be found' do
    render
    expect(rendered).to have_text 'Whatever you are looking for, this is not it'
  end

  it 'provides a contact email address' do
    render
    expect(rendered).to have_selector('a', text: 'hello@openly.one')
  end
end
