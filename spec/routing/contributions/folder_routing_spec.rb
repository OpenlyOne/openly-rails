# frozen_string_literal: true

RSpec.describe 'contributions: routes for folders', type: :routing do
  it 'has a root route' do
    expect(profile_project_contribution_root_folder_path('handle', 'slug', 27))
      .to eq '/handle/slug/contributions/27/files'
    expect(get: '/handle/slug/contributions/27/files').to(
      route_to('contributions/folders#root',
               profile_handle: 'handle', project_slug: 'slug',
               contribution_id: '27')
    )
  end

  it 'has a show route' do
    expect(profile_project_contribution_folder_path('handle', 'slug', 72, 'xy'))
      .to eq '/handle/slug/contributions/72/folders/xy'
    expect(get: '/handle/slug/contributions/55/folders/id').to(
      route_to('contributions/folders#show',
               profile_handle: 'handle', project_slug: 'slug',
               contribution_id: '55', id: 'id')
    )
  end
end
