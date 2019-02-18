# frozen_string_literal: true

RSpec.describe 'routes for contributions: replies', type: :routing do
  let(:index_path) do
    profile_project_contribution_replies_path('handle', 'slug', 27)
  end

  it 'has an index route' do
    expect(index_path).to eq '/handle/slug/contributions/27/replies'
    expect(get: '/handle/slug/contributions/1234/replies').to(
      route_to('contributions/replies#index',
               profile_handle: 'handle',
               project_slug: 'slug',
               contribution_id: '1234')
    )
  end
end
