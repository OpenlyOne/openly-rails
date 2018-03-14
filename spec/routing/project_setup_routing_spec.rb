# frozen_string_literal: true

RSpec.describe 'routes for project setups', type: :routing do
  it 'has a new route' do
    expect(new_profile_project_setup_path('handle', 'slug'))
      .to eq '/handle/slug/setup/new'
    expect(get: '/handle/slug/setup/new').to(
      route_to('project_setups#new', profile_handle: 'handle',
                                     project_slug: 'slug')
    )
  end

  it 'has a create route' do
    expect(profile_project_setup_path('handle', 'slug'))
      .to eq '/handle/slug/setup'
    expect(post: '/handle/slug/setup').to(
      route_to('project_setups#create', profile_handle: 'handle',
                                        project_slug: 'slug')
    )
  end

  it 'has a show route' do
    expect(profile_project_setup_path('handle', 'slug'))
      .to eq '/handle/slug/setup'
    expect(get: '/handle/slug/setup').to(
      route_to('project_setups#show', profile_handle: 'handle',
                                      project_slug: 'slug')
    )
  end
end
