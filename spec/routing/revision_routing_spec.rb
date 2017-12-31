# frozen_string_literal: true

RSpec.describe 'routes for revisions', type: :routing do
  it 'has a new route' do
    expect(new_profile_project_revision_path('handle', 'slug'))
      .to eq '/handle/slug/revisions/new'
    expect(get: '/handle/slug/revisions/new').to(
      route_to('revisions#new', profile_handle: 'handle', project_slug: 'slug')
    )
  end

  it 'has a create route' do
    expect(profile_project_revisions_path('handle', 'slug'))
      .to eq '/handle/slug/revisions'
    expect(post: '/handle/slug/revisions').to(
      route_to('revisions#create', profile_handle: 'handle',
                                   project_slug: 'slug')
    )
  end
end
