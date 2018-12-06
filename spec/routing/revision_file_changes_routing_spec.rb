# frozen_string_literal: true

RSpec.describe 'routes for revision file changes', type: :routing do
  it 'has a show route' do
    expect(
      profile_project_revision_file_change_path(
        'handle', 'slug', 'revision-id', 'file-id'
      )
    ).to eq '/handle/slug/revisions/revision-id/changes/file-id'
    expect(get: '/handle/slug/revisions/revision-id/changes/file-id').to(
      route_to('revisions/file_changes#show',
               profile_handle: 'handle',
               project_slug: 'slug',
               revision_id: 'revision-id',
               id: 'file-id')
    )
  end
end
