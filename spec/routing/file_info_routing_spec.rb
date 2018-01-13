# frozen_string_literal: true

RSpec.describe 'routes for file infos', type: :routing do
  it 'has an index route' do
    expect(profile_project_file_infos_path('handle', 'slug', 'file-id'))
      .to eq '/handle/slug/files/file-id/info'
    expect(get: '/handle/slug/files/file-id/info').to(
      route_to('file_infos#index',
               profile_handle: 'handle',
               project_slug: 'slug',
               id: 'file-id')
    )
  end
end
