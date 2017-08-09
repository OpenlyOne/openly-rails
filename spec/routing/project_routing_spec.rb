# frozen_string_literal: true

RSpec.describe 'routes for projects', type: :routing do
  it 'has a show route' do
    expect(profile_project_path('handle', 'slug')).to eq '/handle/slug'
    expect(get: '/handle/slug').to(
      route_to('projects#show', profile_handle: 'handle', slug: 'slug')
    )
  end
end
