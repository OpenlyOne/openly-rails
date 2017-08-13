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
    # and see the first commit
    expect(page).to have_text 'Welcome to my new project!'
  end

  scenario 'User can view project' do
    # given there is a project
    project = create(:project)

    # when I visit the project's owner
    visit "/#{project.owner.to_param}"
    # and click on the project title
    click_on project.title

    # then I should be on the project's page
    expect(page)
      .to have_current_path profile_project_path(project.owner, project)
    # and I should see the project's title
    expect(page).to have_text project.title
  end

  scenario 'User can edit project' do
    # given there is a project
    project = create(:project)
    # and I am signed in as its owner
    sign_in_as project.owner.account

    # when I visit my project
    visit "/#{project.owner.to_param}/#{project.to_param}"
    # and click on edit
    find('a#edit_project').click
    # and fill in a new title
    fill_in 'project_title',  with: 'My New Project Title'
    fill_in 'Project URL',    with: 'new-slug'
    # and save
    click_on 'Save'

    # then I should be back on project_path
    expect(page)
      .to have_current_path "/#{project.owner.to_param}/new-slug"
    # and see the new project's title
    expect(page).to have_text 'My New Project Title'
    # and see the first commit
    expect(page).to have_text 'Welcome to my new project!'
  end

  scenario 'User can delete project' do
    # given there is a project
    project = create(:project)
    # and I am signed in as its owner
    sign_in_as project.owner.account

    # when I visit my project
    visit "/#{project.owner.to_param}/#{project.to_param}"
    # and click on edit
    find('a#edit_project').click
    # and click on delete
    click_on 'Delete Project'

    # then I should be back on my profile page
    expect(page).to have_current_path profile_path(project.owner)
    # and it should tell me that it was deleted sucessfully
    expect(page).to have_text 'Project successfully deleted.'
    # and it should no longer be in the database
    expect(Project).not_to exist(slug: project.slug)
    # and the repository should be deleted
    expect(VersionControl::Repository.find(project.repository.path)).to be nil
  end
end
