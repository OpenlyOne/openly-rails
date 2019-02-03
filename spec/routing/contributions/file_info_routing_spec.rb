# frozen_string_literal: true

RSpec.describe 'routes for contributions: file infos', type: :routing do
  let(:index_path) do
    profile_project_contribution_file_infos_path(
      'handle', 'slug', 27, 'file-id'
    )
  end

  it 'has an index route' do
    expect(index_path).to eq '/handle/slug/contributions/27/files/file-id/info'
    expect(get: '/handle/slug/contributions/576/files/ABC103/info').to(
      route_to('contributions/file_infos#index',
               profile_handle: 'handle',
               project_slug: 'slug',
               contribution_id: '576',
               id: 'ABC103')
    )
  end
end
