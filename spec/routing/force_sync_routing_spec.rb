# frozen_string_literal: true

RSpec.describe 'routes for force syncs', type: :routing do
  it 'has a create route' do
    expect(profile_project_force_syncs_path('handle', 'slug', 'file-id'))
      .to eq '/handle/slug/files/file-id/sync'
    expect(post: '/handle/slug/files/file-id/sync').to(
      route_to('force_syncs#create',
               profile_handle: 'handle',
               project_slug: 'slug',
               id: 'file-id')
    )
  end
end
