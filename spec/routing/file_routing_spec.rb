# frozen_string_literal: true

RSpec.describe 'routes for projects', type: :routing do
  it 'has an index route' do
    expect(profile_project_files_path('handle', 'slug'))
      .to eq '/handle/slug/files'
    expect(get: '/handle/slug/files')
      .to route_to(
        'files#index',
        profile_handle: 'handle',
        project_slug: 'slug'
      )
  end

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

  it 'has an edit route for content' do
    expect(edit_profile_project_file_path('handle', 'slug', 'name.txt'))
      .to eq '/handle/slug/files/name.txt/edit'
    expect(get: '/handle/slug/files/name.txt/edit')
      .to route_to(
        'files#edit_content',
        profile_handle: 'handle',
        project_slug: 'slug',
        name: 'name.txt'
      )
  end

  it 'has an update route for content' do
    expect(patch: '/handle/slug/files/name.txt/edit')
      .to route_to(
        'files#update_content',
        profile_handle: 'handle',
        project_slug: 'slug',
        name: 'name.txt'
      )
    expect(put: '/handle/slug/files/name.txt/edit')
      .to route_to(
        'files#update_content',
        profile_handle: 'handle',
        project_slug: 'slug',
        name: 'name.txt'
      )
  end

  it 'has an edit route for name' do
    expect(rename_profile_project_file_path('handle', 'slug', 'name.txt'))
      .to eq '/handle/slug/files/name.txt/rename'
    expect(get: '/handle/slug/files/name.txt/rename')
      .to route_to(
        'files#edit_name',
        profile_handle: 'handle',
        project_slug: 'slug',
        name: 'name.txt'
      )
  end

  it 'has an update route for name' do
    expect(patch: '/handle/slug/files/name.txt/rename')
      .to route_to(
        'files#update_name',
        profile_handle: 'handle',
        project_slug: 'slug',
        name: 'name.txt'
      )
    expect(put: '/handle/slug/files/name.txt/rename')
      .to route_to(
        'files#update_name',
        profile_handle: 'handle',
        project_slug: 'slug',
        name: 'name.txt'
      )
  end

  it 'has a delete route' do
    expect(delete_profile_project_file_path('handle', 'slug', 'name.txt'))
      .to eq '/handle/slug/files/name.txt/delete'
    expect(get: '/handle/slug/files/name.txt/delete')
      .to route_to(
        'files#delete',
        profile_handle: 'handle',
        project_slug: 'slug',
        name: 'name.txt'
      )
  end

  it 'has a destroy route' do
    expect(delete: '/handle/slug/files/name.txt/delete')
      .to route_to(
        'files#destroy',
        profile_handle: 'handle',
        project_slug: 'slug',
        name: 'name.txt'
      )
  end
end
