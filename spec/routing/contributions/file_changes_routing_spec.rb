# frozen_string_literal: true

RSpec.describe 'routes for contributions: file changes', type: :routing do
  let(:show_path) do
    profile_project_contribution_file_change_path(
      'handle', 'slug', 567, 'file-id'
    )
  end

  it 'has a show route' do
    expect(show_path).to eq '/handle/slug/contributions/567/changes/file-id'
    expect(get: '/handle/slug/contributions/111/changes/aXB7').to(
      route_to('contributions/file_changes#show',
               profile_handle: 'handle',
               project_slug: 'slug',
               contribution_id: '111',
               id: 'aXB7')
    )
  end
end
