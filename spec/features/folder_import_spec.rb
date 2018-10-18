# frozen_string_literal: true

feature 'Folder Import', :vcr do
  let(:api_connection)  { Providers::GoogleDrive::ApiConnection.new(user_acct) }
  let(:user_acct)       { ENV['GOOGLE_DRIVE_USER_ACCOUNT'] }
  let(:tracking_acct)   { ENV['GOOGLE_DRIVE_TRACKING_ACCOUNT'] }

  # create test folder
  before { prepare_google_drive_test(api_connection) }

  # delete test folder
  after { tear_down_google_drive_test(api_connection) }

  scenario 'Files are imported' do
    # given there is a project
    project = create(:project,
                     title: 'My Awesome New Project!',
                     owner_account_email: user_acct)

    # and a Google Drive folder that contains three files
    3.times do
      create_google_drive_file(parent_id: google_drive_test_folder_id,
                               api_connection: api_connection)
    end

    # and that folder is shared with the tracking account
    api_connection.share_file(google_drive_test_folder_id, tracking_acct)

    # and I wait 5 seconds for Google Drive to propagate the sharing settings to
    # the folder's files
    sleep 5 if VCR.current_cassette.recording?

    # and I am signed in as its owner
    account = project.owner.account
    sign_in_as account

    # when I visit the project's initialization page
    visit "/#{project.owner.to_param}/#{project.to_param}/setup"
    # and fill in the Link to Google Drive Folder
    fill_in 'project_setup_link',
            with: 'https://drive.google.com/drive/folders/' \
                  "#{google_drive_test_folder_id}"
    # and import
    click_on 'Import'

    # then I should see all the files, marked unchanged
    click_on 'Files'
    expect(page).to have_css '.file.no-change', count: 3

    # and I should see one revision
    click_on 'Revisions'
    expect(page).to have_text 'Import Files'

    # and have 3 files in archive
    expect(project.archive.backups.count).to eq 3
  end
end
