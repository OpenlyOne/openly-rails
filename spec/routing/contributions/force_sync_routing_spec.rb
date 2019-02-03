# frozen_string_literal: true

RSpec.describe 'routes for contributions: force syncs', type: :routing do
  let(:index_path) do
    profile_project_contribution_force_syncs_path(
      'handle', 'slug', 27, 'file-id'
    )
  end

  it 'has a create route' do
    expect(index_path).to eq '/handle/slug/contributions/27/files/file-id/sync'
    expect(post: '/handle/slug/contributions/1234/files/xyz/sync').to(
      route_to('contributions/force_syncs#create',
               profile_handle: 'handle',
               project_slug: 'slug',
               contribution_id: '1234',
               id: 'xyz')
    )
  end
end
