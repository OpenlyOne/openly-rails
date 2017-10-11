# frozen_string_literal: true

RSpec.describe 'routes for discussions', type: :routing do
  it 'has a show route' do
    expect(get: '/handle/slug/discussions/1')
      .to route_to(
        'discussions#show',
        profile_handle: 'handle',
        project_slug: 'slug',
        discussion_type: 'discussions',
        scoped_id: '1'
      )
  end
end
