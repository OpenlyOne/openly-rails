# frozen_string_literal: true

require 'support/helpers/settings_helper.rb'
RSpec.configure do |c|
  c.extend SettingsHelper
end

RSpec.describe 'devise/registrations/new', type: :view do
  enable_account_registration

  before do
    without_partial_double_verification do
      allow(view).to receive(:resource).and_return Account.new
      allow(view).to receive(:resource_name).and_return :account
      allow(view).to(
        receive(:devise_mapping).and_return(Devise.mappings[:account])
      )
    end
  end

  it 'links to log in page' do
    render
    expect(rendered).to have_link('Login', href: new_session_path)
  end
end
