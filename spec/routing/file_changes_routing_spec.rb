# frozen_string_literal: true

RSpec.describe 'routes for file changes', type: :routing do
  it 'has a show route' do
    expect(profile_project_file_change_path('handle', 'slug', 'file-id'))
      .to eq '/handle/slug/changes/file-id'
    expect(get: '/handle/slug/changes/file-id').to(
      route_to('file_changes#show',
               profile_handle: 'handle',
               project_slug: 'slug',
               id: 'file-id')
    )
  end
end
