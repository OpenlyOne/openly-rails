# frozen_string_literal: true

feature 'Folder Import' do
  scenario 'Files are imported' do
    mock_google_drive_requests if ENV['MOCK_GOOGLE_DRIVE_REQUESTS'] == 'true'

    # given there is a project
    project = create(:project, title: 'My Awesome New Project!')

    # and I am signed in as its owner
    account = project.owner.account
    sign_in_as account

    # when I visit the project's initialization page
    visit "/#{project.owner.to_param}/#{project.to_param}/setup"
    # and fill in the Link to Google Drive Folder
    fill_in 'project_link_to_google_drive_folder',
            with: Settings.google_drive_test_folder
    # and import
    click_on 'Import'
    # and go to files
    click_on 'Files'

    # then I should see all the files
    expect(page).to have_css '.file', count: 3

    # and see no file modifiation icons
    expect(page).not_to have_css '.file.changed'
    expect(page).to have_css '.file.unchanged', count: 3
  end
end
