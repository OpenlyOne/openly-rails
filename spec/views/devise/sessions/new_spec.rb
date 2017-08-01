# frozen_string_literal: true

RSpec.describe 'devise/sessions/new', type: :view do
  before do
    without_partial_double_verification do
      allow(view).to receive(:resource).and_return Account.new
      allow(view).to receive(:resource_name).and_return :account
      allow(view).to(
        receive(:devise_mapping).and_return(Devise.mappings[:account])
      )
    end
  end

  it 'links to sign up page' do
    render
    expect(rendered).to have_link('Sign up', href: new_registration_path)
  end
end
