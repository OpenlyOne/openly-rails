# frozen_string_literal: true

RSpec.describe 'routes for errors', type: :routing do
  it 'has a 404 route' do
    expect(get: '/404').to route_to 'errors#not_found'
  end

  it 'has a 422 route' do
    expect(get: '/422').to route_to 'errors#unacceptable'
  end

  it 'has a 500 route' do
    expect(get: '/500').to route_to 'errors#internal_server_error'
  end
end
