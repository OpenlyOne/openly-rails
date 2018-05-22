# frozen_string_literal: true

RSpec.describe 'routes for project overviews', type: :routing do
  it 'has an overview route' do
    expect(profile_project_overview_path('handle', 'slug'))
      .to eq '/handle/slug/overview'
    expect(get: '/handle/slug/overview').to(
      route_to('project_overviews#show',
               profile_handle: 'handle',
               project_slug: 'slug')
    )
  end
end
