# frozen_string_literal: true

feature 'Contributions: Force Sync', :vcr do
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
  let(:contribution) do
    create :contribution, :setup,
           creator: current_account.user, project: project
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
    # and I have a contribution
    contribution

    # when I update the file
    folder_copy = contribution.files.find_by_name(folder.name).remote
    file_copy   = contribution.files.find_by_name(file.name).remote
    file_copy.rename('Doc ABC')
    file_copy.relocate(from: file_copy.parent_id, to: folder_copy.id)
    file_copy.update_content('new file content')

    # and force sync the file
    visit "#{project.owner.to_param}/#{project.to_param}"
    click_on 'Contributions'
    click_on contribution.title
    within '.page-subheading' do
      click_on 'Files'
    end
    # files are sorted folder first, so let's click on the last .file-info btn
    all('.file-info').last.click
    click_on 'Force Sync'

    # then I should see a success message
    expect(page).to have_text 'File successfully synced.'

    # and be on the file info page for the contribution
    expect(page).to have_current_path(
      "/#{project.owner.to_param}/#{project.to_param}" \
      "/contributions/#{contribution.id}" \
      "/files/#{contribution.files.find_by_name('Doc ABC').hashed_file_id}/info"
    )

    # and see the file as modified, renamed, and moved
    expect(page).to have_css '.file.modification', text: 'Doc ABC'
    expect(page).to have_css '.file.rename', text: 'Doc ABC'
    expect(page).to have_css '.file.movement', text: 'Doc ABC'
    expect(page).to have_css '.fragment.addition', text: 'new file content'

    # and have a backup of the file
    staged = contribution.files.find_by_remote_file_id(file_copy.id)
    backup = staged.current_version.backup
    expect(backup.remote.name).to eq(staged.name)
    expect(backup.remote.parent_id).to eq(project.archive.remote_file_id)
  end
end
