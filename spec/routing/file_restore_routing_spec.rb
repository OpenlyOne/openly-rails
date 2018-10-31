# frozen_string_literal: true

RSpec.describe 'routes for file restores', type: :routing do
  it 'has a create route' do
    expect(profile_project_file_restores_path('handle', 'slug', 'snapshot-id'))
      .to eq '/handle/slug/snapshots/snapshot-id/restore'
    expect(post: '/handle/slug/snapshots/snapshot-id/restore').to(
      route_to('file_restores#create',
               profile_handle: 'handle',
               project_slug: 'slug',
               id: 'snapshot-id')
    )
  end
end
