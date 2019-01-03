# frozen_string_literal: true

feature 'Project' do
  let(:user_account_email)  { ENV['GOOGLE_DRIVE_USER_ACCOUNT'] }
  let(:project_owner)       { create(:user, account: user_account) }
  let(:user_account)        { build(:account, email: user_account_email) }

  # create test folder
  before(:each, :vcr) { prepare_google_drive_test }

  # delete test folder
  after(:each, :vcr) { tear_down_google_drive_test }

  scenario 'User can create project', :vcr do
    # given I am signed in as its owner
    account = user_account.tap(&:save)
    sign_in_as account

    # when I click on 'New Project'
    within 'nav' do
      click_on 'New Project'
    end
    # and fill in title and slug
    fill_in 'project_title', with: 'My Awesome New Project!'
    # and save
    click_on 'Create'

    # then I should be on the project page
    expect(page).to have_current_path(
      "/#{account.user.to_param}/my-awesome-new-project/setup/new"
    )
    # and see the new project's title
    expect(page).to have_text 'My Awesome New Project!'
    # and see a success message
    expect(page).to have_text 'Project successfully created.'
    # and have set up an archive folder on Google Drive
    expect(Project.first.archive).to be_present
    # and a repository and master branch
    expect(Project.first.repository).to be_present
    expect(Project.first.master_branch).to be_present
  end

  scenario 'User can view project' do
    # given there is a project
    project = create(:project, :skip_archive_setup, :setup_complete)
    create :vcs_file_in_branch, :root, branch: project.master_branch
    # with two collaborators
    collaborators = create_list :user, 2
    project.collaborators << collaborators

    sign_in_as project.owner.account

    # when I visit the project's owner
    visit "/#{project.owner.to_param}"
    # and click on the project title
    click_on project.title
    # and click on Overview
    click_on 'Overview'

    # then I should be on the project's files page
    expect(page).to have_current_path(
      profile_project_overview_path(project.owner, project)
    )
    # and I should see the project's title
    expect(page).to have_text project.title
    # and the project's owner and collaborators
    expect(page).to have_text project.owner.name
    expect(page).to have_text collaborators.first.name
    expect(page).to have_text collaborators.last.name
    # TODO: Grant view access to archive folder & check result
  end

  scenario 'User can edit project' do
    # given there is a project
    project = create(:project, :skip_archive_setup)
    # and I am signed in as its owner
    sign_in_as project.owner.account

    # when I visit my project's overview page
    visit "/#{project.owner.to_param}/#{project.to_param}/overview"
    # and click on edit
    find('a#edit_project').click
    # and fill in a new title
    fill_in 'project_title',  with: 'My New Project Title'
    fill_in 'Project URL',    with: 'new-slug'
    fill_in 'Description',    with: 'My Description'
    fill_in 'Tags',           with: 'climate   change,education , Health, NGO'
    # and save
    click_on 'Save'

    # then I should be back on project_path
    expect(page)
      .to have_current_path "/#{project.owner.to_param}/new-slug/overview"
    # and see the project's new title
    expect(page).to have_text 'My New Project Title'
    # and see the project's new tags
    expect(page).to have_text 'Climate Change'
    expect(page).to have_text 'Education'
    expect(page).to have_text 'Health'
    expect(page).to have_text 'NGO'
    # and see the project's new description
    expect(page).to have_text 'My Description'
    # and see a success message
    expect(page).to have_text 'Project successfully updated.'
    # TODO: Rename archive folder & check result
  end

  scenario 'User can delete project' do
    # given there is a project
    project = create(:project, :skip_archive_setup)
    # and I am signed in as its owner
    sign_in_as project.owner.account

    # when I visit my project's overview page
    visit "/#{project.owner.to_param}/#{project.to_param}/overview"
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
    # TODO: Delete archive folder & check result
  end
end
