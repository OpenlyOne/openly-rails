# frozen_string_literal: true

RSpec.describe 'routes for contributions', type: :routing do
  it 'has an index route' do
    expect(profile_project_contributions_path('handle', 'slug'))
      .to eq '/handle/slug/contributions'
    expect(get: '/handle/slug/contributions').to(
      route_to('contributions#index', profile_handle: 'handle',
                                      project_slug: 'slug')
    )
  end

  it 'has a new route' do
    expect(new_profile_project_contribution_path('handle', 'slug'))
      .to eq '/handle/slug/contributions/new'
    expect(get: '/handle/slug/contributions/new').to(
      route_to('contributions#new', profile_handle: 'handle',
                                    project_slug: 'slug')
    )
  end

  it 'has a create route' do
    expect(profile_project_contributions_path('handle', 'slug'))
      .to eq '/handle/slug/contributions'
    expect(post: '/handle/slug/contributions').to(
      route_to('contributions#create', profile_handle: 'handle',
                                       project_slug: 'slug')
    )
  end

  it 'has a show route' do
    expect(profile_project_contribution_path('handle', 'slug', 27))
      .to eq '/handle/slug/contributions/27'
    expect(get: '/handle/slug/contributions/42').to(
      route_to('contributions#show', profile_handle: 'handle',
                                     project_slug: 'slug',
                                     id: '42')
    )
  end
end
