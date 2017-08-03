# frozen_string_literal: true

require 'support/helpers/settings_helper.rb'
RSpec.configure do |c|
  c.extend SettingsHelper
end

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

  context 'when registration is enabled' do
    enable_account_registration

    it 'links to sign up page' do
      render
      expect(rendered).to have_link('Join', href: new_registration_path)
    end
  end

  context 'when registrations is disabled' do
    disable_account_registration

    it 'does not raise an error' do
      expect { render }.not_to raise_error
    end
  end
end
