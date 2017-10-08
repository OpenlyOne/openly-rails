# frozen_string_literal: true

feature 'Reply' do
  scenario 'User can list replies' do
    # given there is a suggestion
    discussion = create(:discussions_suggestion)
    project = discussion.project
    # with three replies
    replies = create_list(:reply, 3, discussion: discussion)

    # when I visit the discussion
    visit profile_project_discussion_path(project.owner,
                                          project,
                                          discussion.type_to_url_segment,
                                          discussion)

    # then I should be on the discussion page
    expect(page).to have_current_path(
      profile_project_discussion_path(
        project.owner, project, discussion.type_to_url_segment, discussion
      )
    )

    # and I should see the three replies
    replies.each do |reply|
      expect(page).to have_text reply.author.name
      expect(page).to have_text reply.content
    end
  end
end
