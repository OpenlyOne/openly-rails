# frozen_string_literal: true

RSpec.describe 'routes for folders', type: :routing do
  it 'has a root route' do
    expect(profile_project_root_folder_path('handle', 'slug'))
      .to eq '/handle/slug/files'
    expect(get: '/handle/slug/files').to(
      route_to('folders#root', profile_handle: 'handle', project_slug: 'slug')
    )
  end

  it 'has a show route' do
    expect(profile_project_folder_path('handle', 'slug', '123'))
      .to eq '/handle/slug/folders/123'
    expect(get: '/handle/slug/folders/google_drive_id').to(
      route_to('folders#show', profile_handle: 'handle', project_slug: 'slug',
                               google_drive_id: 'google_drive_id')
    )
  end
end
