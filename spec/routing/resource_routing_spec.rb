# frozen_string_literal: true

RSpec.describe 'routes for resources', type: :routing do
  it 'has show route' do
    expect(resource_path('id')).to eq '/resources/id'
    expect(get: '/resources/id').to route_to('resources#show', id: 'id')
  end
end
