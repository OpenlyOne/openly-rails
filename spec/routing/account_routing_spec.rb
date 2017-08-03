# frozen_string_literal: true

require 'support/helpers/settings_helper.rb'
RSpec.configure do |c|
  c.extend SettingsHelper
end

RSpec.describe 'routes for accounts', type: :routing do
  it 'has an edit route' do
    expect(edit_account_path).to eq '/account'
    expect(get: '/account').to route_to 'devise/registrations#edit'
  end

  it 'has an update route' do
    expect(account_path).to eq '/account'
    expect(patch: '/account').to route_to 'devise/registrations#update'
    expect(put:   '/account').to route_to 'devise/registrations#update'
  end

  it 'has a delete route' do
    expect(account_path).to eq '/account'
    expect(delete: '/account').to route_to 'devise/registrations#destroy'
  end

  it 'has a root route' do
    expect(account_root_path).to eq '/account'
  end

  context 'when registrations are enabled' do
    enable_account_registration

    it 'has a new route' do
      expect(new_registration_path).to eq '/join'
      expect(get: '/join').to route_to 'devise/registrations#new'
    end

    it 'has a create route' do
      expect(registration_path).to eq '/join'
      expect(post: '/join').to route_to 'devise/registrations#create'
    end
  end

  context 'when registrations are disabled' do
    disable_account_registration

    it 'does not have a new route' do
      expect { new_registration_path }.to raise_error NameError
      expect(get: '/join').not_to be_routable
    end

    it 'does not have a create route' do
      expect { registration_path }.to raise_error NameError
      expect(post: '/join').not_to be_routable
    end
  end
end
