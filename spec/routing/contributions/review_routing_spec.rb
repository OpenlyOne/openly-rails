# frozen_string_literal: true

RSpec.describe 'routes for contributions: review', type: :routing do
  it 'has a show route' do
    expect(profile_project_contribution_review_path('handle', 'slug', 5678))
      .to eq '/handle/slug/contributions/5678/review'
    expect(get: '/handle/slug/contributions/1234/review').to(
      route_to('contributions/reviews#show',
               profile_handle: 'handle',
               project_slug: 'slug',
               contribution_id: '1234')
    )
  end
end
