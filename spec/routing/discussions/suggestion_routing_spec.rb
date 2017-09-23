# frozen_string_literal: true

RSpec.describe 'routes for suggestions', type: :routing do
  it 'has a new route' do
    expect(new_profile_project_discussion_path('handle', 'slug', 'suggestions'))
      .to eq '/handle/slug/suggestions/new'
    expect(get: '/handle/slug/suggestions/new')
      .to route_to(
        'discussions#new',
        profile_handle: 'handle',
        project_slug: 'slug',
        type: 'suggestions'
      )
  end

  it 'has a create route' do
    expect(post: '/handle/slug/suggestions')
      .to route_to(
        'discussions#create',
        profile_handle: 'handle',
        project_slug: 'slug',
        type: 'suggestions'
      )
  end
end
