# frozen_string_literal: true

feature 'Revision' do
  scenario 'User can create revision' do
    # given there is a project
    project = create :project
    # and I am signed in as its owner
    sign_in_as project.owner.account
    # with some files and folders
    root = create :file, :root, repository: project.repository
    create_list :file, 5, parent: root

    # when I visit the project page
    visit "#{project.owner.to_param}/#{project.to_param}"
    # and click on Filess
    click_on 'Files'
    # and click on Commit Changes
    click_on 'Commit Changes'
    # and enter a revision summary
    fill_in 'Summary', with: 'Initial Commit'
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
  end
end
