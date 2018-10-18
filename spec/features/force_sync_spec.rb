# frozen_string_literal: true

feature 'Force Sync', :vcr do
  let(:api_connection)  { Providers::GoogleDrive::ApiConnection.new(user_acct) }
  let(:user_acct)       { ENV['GOOGLE_DRIVE_USER_ACCOUNT'] }
  let(:tracking_acct)   { ENV['GOOGLE_DRIVE_TRACKING_ACCOUNT'] }

  # create test folder
  before { prepare_google_drive_test(api_connection) }
  # share test folder
  before do
    api_connection
      .share_file(google_drive_test_folder_id, tracking_acct, :writer)
  end

  # delete test folder
  after { tear_down_google_drive_test(api_connection) }

  let(:current_account) { create :account, email: user_acct }
  let(:project) { create :project, owner: current_account.user }
  let(:setup) { create :project_setup, link: link_to_folder, project: project }
  let(:link_to_folder) do
    "https://drive.google.com/drive/folders/#{google_drive_test_folder_id}"
  end

  before { sign_in_as current_account }

  scenario 'User can force sync file' do
    # given a folder within the project folder
    folder = create_google_drive_file(
      name: 'Folder',
      parent_id: google_drive_test_folder_id,
      mime_type: Providers::GoogleDrive::MimeType.folder,
      api_connection: api_connection
    )
    # and a file within the project folder
    file = create_google_drive_file(
      name: 'Doc XYZ',
      parent_id: google_drive_test_folder_id,
      api_connection: api_connection
    )

    # given project is imported and changes committed
    setup

    # when I update the file
    file.rename('Doc ABC')
    file.relocate(from: file.parent_id, to: folder.id)
    api_connection.update_file_content(file.id, 'new file content')

    # and force sync the file
    visit "#{project.owner.to_param}/#{project.to_param}/files/#{file.id}/info"
    click_on 'Force Sync'

    # then I should see a success message
    expect(page).to have_text 'File successfully synced.'

    # and see the file as modified, renamed, and moved
    expect(page).to have_css '.file.modification', text: 'Doc ABC'
    expect(page).to have_css '.file.rename', text: 'Doc ABC'
    expect(page).to have_css '.file.movement', text: 'Doc ABC'
  end
end
