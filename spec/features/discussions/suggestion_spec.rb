# frozen_string_literal: true

feature 'Discussions::Suggestion' do
  scenario 'User can create suggestion' do
    # given I am signed in as a user
    sign_in_as create(:account)
    # and there is a project
    project = create(:project)

    # when I visit the page to create a new suggestion for the project
    visit(
      new_profile_project_discussion_path(project.owner, project, 'suggestions')
    )
    # and fill in the title
    fill_in 'Title', with: 'Add information about frogs'
    # and create the suggestion
    click_on 'Create'

    # then I should be on the suggestion page
    # expect(page).to have_current_path(
    #   profile_project_discussion_path(
    #     project.owner, project, 'suggestions', 1
    #   )
    # )
    # and see the new suggestion's title
    # expect(page).to have_text 'Add information about frogs'
    # and there should be one suggestion in the database
    expect(project.suggestions.count).to eq 1
  end
end
