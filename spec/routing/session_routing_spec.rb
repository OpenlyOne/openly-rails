# frozen_string_literal: true

RSpec.describe 'routes for sessions', type: :routing do
  it 'has a login route' do
    expect(new_account_session_path).to eq '/accounts/sign_in'
    expect(get: '/accounts/sign_in').to route_to 'devise/sessions#new'
  end

  it 'has a create route' do
    expect(account_session_path).to eq '/accounts/sign_in'
    expect(post: '/accounts/sign_in').to route_to 'devise/sessions#create'
  end

  it 'has a destroy route' do
    expect(destroy_account_session_path).to eq '/accounts/sign_out'
    expect(get: '/accounts/sign_out').to route_to 'devise/sessions#destroy'
  end
end
