# frozen_string_literal: true

RSpec.describe 'routes for revision restores', type: :routing do
  it 'has a create route' do
    expect(profile_project_revision_restores_path('handle', 'slug', 'r-id'))
      .to eq '/handle/slug/revisions/r-id/restore'
    expect(post: '/handle/slug/revisions/revision-id/restore').to(
      route_to('revisions/restores#create',
               profile_handle: 'handle',
               project_slug: 'slug',
               revision_id: 'revision-id')
    )
  end

  it 'has a show route' do
    expect(restore_status_profile_project_revisions_path('handle', 'slug'))
      .to eq '/handle/slug/revisions/restore/status'
    expect(get: '/handle/slug/revisions/restore/status').to(
      route_to('revisions/restores#show',
               profile_handle: 'handle',
               project_slug: 'slug')
    )
  end
end
