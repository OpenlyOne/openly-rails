# frozen_string_literal: true

RSpec.describe 'routes for sessions', type: :routing do
  it 'has a new route' do
    expect(new_session_path).to eq '/login'
    expect(get: '/login').to route_to 'devise/sessions#new'
  end

  it 'has a create route ' do
    expect(session_path).to eq '/login'
    expect(get: '/login').to route_to 'devise/sessions#new'
  end

  it 'has a destroy route' do
    expect(destroy_session_path).to eq '/logout'
    expect(get: '/logout').to route_to 'devise/sessions#destroy'
  end

  it 'has a new_account_session_path for Devise' do
    expect(new_account_session_path).to eq new_session_path
  end
end
