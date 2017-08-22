# frozen_string_literal: true

RSpec.describe 'routes for projects', type: :routing do
  it 'has a show route' do
    expect(profile_project_file_path('handle', 'slug', 'name.txt'))
      .to eq '/handle/slug/files/name.txt'
    expect(get: '/handle/slug/files/name.txt')
      .to route_to(
        'files#show',
        profile_handle: 'handle',
        project_slug: 'slug',
        name: 'name.txt'
      )
  end
end
