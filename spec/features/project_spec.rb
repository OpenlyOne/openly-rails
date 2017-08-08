# frozen_string_literal: true

feature 'Project' do
  scenario 'User can create project' do
    # given I am signed in as its owner
    account = create(:account)
    sign_in_as account

    # when I click on 'New Project'
    within 'nav' do
      click_on 'New Project'
    end
    # and fill in title and slug
    fill_in 'project_title',  with: 'My Awesome New Project!'
    fill_in 'Project URL',    with: 'my-awesome-new-project'
    # and save
    click_on 'Create Project'

    # then I should be on the project page
    expect(page)
      .to have_current_path "/#{account.user.to_param}/my-awesome-new-project"
    # and see the new project's title
    expect(page).to have_text 'My Awesome New Project!'
  end

  scenario 'User can view project' do
    # given there is a project
    project = create(:project)

    # when I visit the project
    visit "/#{project.owner.handle.identifier}/#{project.slug}"

    # then I should see the project's title
    expect(page).to have_text project.title
  end
end
