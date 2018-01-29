# frozen_string_literal: true

feature 'Collaborators' do
  scenario 'As a collaborator, the project is listed on my profile' do
    # given there is a project
    project = create :project
    # and I am signed in as a user
    me = create :user
    sign_in_as me.account
    # who is added to that project's Collaborators
    project.collaborators << me

    # when I visit my profile page
    visit me.to_param.to_s

    # then I should see the project
    expect(page).to have_text project.title
  end

  scenario 'As a collaborator, I can create a new revision' do
    # given there is a project
    project = create :project
    # and I am signed in as a user
    me = create :user
    sign_in_as me.account
    # who is added to that project's Collaborators
    project.collaborators << me
    # and the project has some files
    root = create :file, :root, repository: project.repository
    create_list :file, 5, parent: root

    # when I visit the project page
    visit "#{project.owner.to_param}/#{project.to_param}"
    # and click on Files
    click_on 'Files'
    # and click on Commit Changes
    click_on 'Commit Changes'
    # and enter a revision title
    fill_in 'Title', with: 'Initial Commit'
    # and click on 'Commit'
    click_on 'Commit'

    # then I should be on the project's files page
    expect(page).to have_current_path(
      "/#{project.owner.to_param}/#{project.to_param}/files"
    )
    # and see a success message
    expect(page).to have_text 'Revision successfully created.'
    # and have the revision persisted to the repository
    expect(project.repository.revisions.last).to be_present
    # and see no file modification icons
    expect(page).to have_css '.file.unchanged', count: 5
  end
end
