# frozen_string_literal: true

RSpec.describe 'routes for revision folders', type: :routing do
  it 'has a root route' do
    expect(profile_project_revision_root_folder_path('handle', 'slug', '123'))
      .to eq '/handle/slug/revisions/123/files'
    expect(get: '/handle/slug/revisions/123/files').to(
      route_to('revisions/folders#root', profile_handle: 'handle',
                                         project_slug: 'slug',
                                         revision_id: '123')
    )
  end

  it 'has a show route' do
    expect(profile_project_revision_folder_path('handle', 'slug', '123', 'abc'))
      .to eq '/handle/slug/revisions/123/folders/abc'
    expect(get: '/handle/slug/revisions/123/folders/abc').to(
      route_to('revisions/folders#show', profile_handle: 'handle',
                                         project_slug: 'slug',
                                         revision_id: '123',
                                         id: 'abc')
    )
  end
end
