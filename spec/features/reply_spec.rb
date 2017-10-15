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

  scenario 'User can create reply' do
    # given I am signed in as a user
    sign_in_as create(:user, name: 'Benjamin Button').account
    # and there is an issue
    discussion = create(:discussions_issue)
    project = discussion.project

    # when I visit the discussion
    visit profile_project_discussion_path(project.owner,
                                          project,
                                          discussion.type_to_url_segment,
                                          discussion)
    # and fill in the content
    fill_in 'Content', with: 'Could you provide a few more details?'
    # and save
    click_on 'Reply'

    # then I should be on the discussion page
    expect(page).to have_current_path(
      profile_project_discussion_path(
        project.owner, project, discussion.type_to_url_segment, discussion
      )
    )
    # and see the new reply's content
    expect(page).to have_text 'Could you provide a few more details?'
    # and see my name
    expect(page).to have_text 'Benjamin Button'
  end
end
