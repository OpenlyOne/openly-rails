# frozen_string_literal: true

RSpec.describe 'routes for signups', type: :routing do
  it 'has a create route ' do
    expect(post: '/signup').to route_to 'signups#create'
  end
end
