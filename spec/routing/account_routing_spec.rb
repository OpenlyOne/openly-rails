# frozen_string_literal: true

RSpec.describe 'routes for accounts', type: :routing do
  it 'has a new route' do
    expect(new_registration_path).to eq '/join'
    expect(get: '/join').to route_to 'devise/registrations#new'
  end

  it 'has a create route' do
    expect(registration_path).to eq '/join'
    expect(post: '/join').to route_to 'devise/registrations#create'
  end

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
end
