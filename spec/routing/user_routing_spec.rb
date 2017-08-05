# frozen_string_literal: true

RSpec.describe 'routes for users', type: :routing do
  it 'has a show route' do
    expect(user_path(1)).to eq '/users/1'
    expect(get: '/users/2').to route_to 'users#show', id: '2'
  end
end
