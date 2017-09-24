# frozen_string_literal: true

RSpec.shared_examples 'implementing discussion features' do |discussion_type|
  scenario "User can list #{discussion_type}" do
    # given there is a project
    project = create(:project)
    # with three discussions
    discussions =
      create_list("discussions_#{discussion_type.singularize}".to_sym, 3,
                  project: project)

    # when I visit the project
    visit profile_project_path(project.owner, project)
    # and click on the discussions type
    click_on discussion_type.titleize

    # then I should be on the discussion page
    expect(page).to have_current_path(
      profile_project_discussions_path(
        project.owner, project, discussion_type
      )
    )

    # and I should see the three discussions
    discussions.each do |discussion|
      expect(page).to have_link(
        discussion.title,
        href: profile_project_discussion_path(
          project.owner,
          project,
          discussion_type,
          discussion
        )
      )
    end
  end

  scenario "User can create #{discussion_type}" do
    # given I am signed in as a user
    sign_in_as create(:account)
    # and there is a project
    project = create(:project)

    # when I visit the project
    visit profile_project_path(project.owner, project)
    # and click on the discussion type
    click_on discussion_type.titleize
    # and click on add
    find("a#new-project-#{discussion_type.singularize}").click
    # and fill in the title
    fill_in 'Title', with: 'Add information about frogs'
    # and create the discussion
    click_on 'Create'

    # then I should be on the discussion page
    expect(page).to have_current_path(
      profile_project_discussion_path(
        project.owner, project, discussion_type, Discussions::Base.last
      )
    )
    # and see the new discussion's title
    expect(page).to have_text 'Add information about frogs'
    # and there should be one discussion in the database
    expect(project.send(discussion_type.to_sym).count).to eq 1
  end

  scenario "User can view #{discussion_type}" do
    # given I am signed in as a user
    sign_in_as create(:account)
    # and there is a project with a discussion
    discussion  = create("discussions_#{discussion_type.singularize}".to_sym)
    project     = discussion.project

    # when I visit the project
    visit profile_project_path(project.owner, project)
    # and click on the discussion type
    click_on discussion_type.titleize
    # and click on the discussion
    click_on discussion.title

    # then I should be on the discussion's page
    expect(page).to have_current_path(
      profile_project_discussion_path(
        project.owner, project, discussion_type, discussion
      )
    )
    # and see the discussion's title
    expect(page).to have_text discussion.title
  end
end
