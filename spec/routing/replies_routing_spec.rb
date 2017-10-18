# frozen_string_literal: true

RSpec.describe 'routes for projects', type: :routing do
  it 'has an index route' do
    expect(
      profile_project_discussion_replies_path('handle', 'slug',
                                              'suggestions', 1)
    ).to eq '/handle/slug/suggestions/1/replies'
    expect(
      profile_project_discussion_replies_path('handle', 'slug',
                                              'issues', 100)
    ).to eq '/handle/slug/issues/100/replies'
    expect(
      profile_project_discussion_replies_path('handle', 'slug',
                                              'questions', 53_267)
    ).to eq '/handle/slug/questions/53267/replies'
    expect(get: '/handle/slug/suggestions/99/replies')
      .to route_to(
        'replies#index',
        profile_handle: 'handle',
        project_slug: 'slug',
        discussion_type: 'suggestions',
        discussion_scoped_id: '99'
      )
  end

  it 'has a create route' do
    expect(post: '/handle/slug/suggestions/1/replies')
      .to route_to(
        'replies#create',
        profile_handle: 'handle',
        project_slug: 'slug',
        discussion_type: 'suggestions',
        discussion_scoped_id: '1'
      )
    expect(post: '/handle/slug/issues/1/replies')
      .to route_to(
        'replies#create',
        profile_handle: 'handle',
        project_slug: 'slug',
        discussion_type: 'issues',
        discussion_scoped_id: '1'
      )
    expect(post: '/handle/slug/questions/1/replies')
      .to route_to(
        'replies#create',
        profile_handle: 'handle',
        project_slug: 'slug',
        discussion_type: 'questions',
        discussion_scoped_id: '1'
      )
  end
end
