# frozen_string_literal: true

RSpec.describe 'routes for projects', type: :routing do
  it 'has a new route' do
    expect(new_project_path).to eq '/projects/new'
    expect(get: '/projects/new').to route_to 'projects#new'
  end

  it 'has a create route' do
    expect(projects_path).to eq '/projects/new'
    expect(post: '/projects/new').to route_to 'projects#create'
  end

  it 'has a show route' do
    expect(profile_project_path('handle', 'slug')).to eq '/handle/slug'
    expect(get: '/handle/slug').to(
      route_to('projects#show', profile_handle: 'handle', slug: 'slug')
    )
  end
end
