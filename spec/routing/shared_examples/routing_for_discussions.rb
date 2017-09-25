# frozen_string_literal: true

RSpec.shared_examples 'routing for discussions' do |discussion_type|
  it 'has an index route' do
    expect(profile_project_discussions_path('handle', 'slug', discussion_type))
      .to eq "/handle/slug/#{discussion_type}"
    expect(get: "/handle/slug/#{discussion_type}")
      .to route_to(
        'discussions#index',
        profile_handle: 'handle',
        project_slug: 'slug',
        type: discussion_type
      )
  end

  it 'has a new route' do
    expect(
      new_profile_project_discussion_path('handle', 'slug', discussion_type)
    ).to eq "/handle/slug/#{discussion_type}/new"
    expect(get: "/handle/slug/#{discussion_type}/new")
      .to route_to(
        'discussions#new',
        profile_handle: 'handle',
        project_slug: 'slug',
        type: discussion_type
      )
  end

  it 'has a create route' do
    expect(post: "/handle/slug/#{discussion_type}")
      .to route_to(
        'discussions#create',
        profile_handle: 'handle',
        project_slug: 'slug',
        type: discussion_type
      )
  end

  it 'has a show route' do
    expect(
      profile_project_discussion_path('handle', 'slug', discussion_type, 1)
    ).to eq "/handle/slug/#{discussion_type}/1"
    expect(get: "/handle/slug/#{discussion_type}/1")
      .to route_to(
        'discussions#show',
        profile_handle: 'handle',
        project_slug: 'slug',
        type: discussion_type,
        scoped_id: '1'
      )
  end
end
