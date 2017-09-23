# frozen_string_literal: true

feature 'Discussions::Suggestion' do
  scenario 'User can list suggestions' do
    # given there is a project
    project = create(:project)
    # with three suggestions
    suggestions = create_list(:discussions_suggestion, 3, project: project)

    # when I visit the project
    visit profile_project_path(project.owner, project)
    # and click on suggestions
    click_on 'Suggestions'

    # then I should be on the suggestions page
    expect(page).to have_current_path(
      profile_project_discussions_path(
        project.owner, project, 'suggestions'
      )
    )

    # and I should see the three suggestions
    suggestions.each do |suggestion|
      expect(page).to have_link(
        suggestion.title,
        href: profile_project_discussion_path(
          project.owner,
          project,
          'suggestions',
          suggestion
        )
      )
    end
  end

  scenario 'User can create suggestion' do
    # given I am signed in as a user
    sign_in_as create(:account)
    # and there is a project
    project = create(:project)

    # when I visit the project
    visit profile_project_path(project.owner, project)
    # and click on suggestions
    click_on 'Suggestions'
    # and click on add
    find('a#new-project-suggestion').click
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
