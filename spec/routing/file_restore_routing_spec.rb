# frozen_string_literal: true

RSpec.describe 'routes for file restores', type: :routing do
  it 'has a create route' do
    expect(profile_project_file_restores_path('handle', 'slug', 'version-id'))
      .to eq '/handle/slug/versions/version-id/restore'
    expect(post: '/handle/slug/versions/version-id/restore').to(
      route_to('file_restores#create',
               profile_handle: 'handle',
               project_slug: 'slug',
               id: 'version-id')
    )
  end
end
