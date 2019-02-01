# frozen_string_literal: true

RSpec.describe 'routes for contributions: acceptance', type: :routing do
  it 'has a create route' do
    expect(profile_project_contribution_acceptance_path('handle', 'slug', 27))
      .to eq '/handle/slug/contributions/27/accept'
    expect(post: '/handle/slug/contributions/1234/accept').to(
      route_to('contributions/acceptances#create',
               profile_handle: 'handle',
               project_slug: 'slug',
               contribution_id: '1234')
    )
  end
end
