# frozen_string_literal: true

feature 'File Restore', vcr: true do
  let(:api_connection)  { Providers::GoogleDrive::ApiConnection.new(user_acct) }
  let(:user_acct)       { ENV['GOOGLE_DRIVE_USER_ACCOUNT'] }
  let(:tracking_acct)   { ENV['GOOGLE_DRIVE_TRACKING_ACCOUNT'] }

  # create test folder
  before { prepare_google_drive_test(api_connection) }
  let!(:remote_subfolder) do
    Providers::GoogleDrive::FileSync.create(
      name: 'Folder',
      parent_id: google_drive_test_folder_id,
      mime_type: Providers::GoogleDrive::MimeType.folder,
      api_connection: api_connection
    )
  end

  let!(:remote_file) do
    Providers::GoogleDrive::FileSync.create(
      name: 'original name',
      parent_id: remote_subfolder.id,
      mime_type: remote_file_mime_type,
      api_connection: api_connection
    )
  end
  let(:remote_file_mime_type) { Providers::GoogleDrive::MimeType.document }
  # share test folder
  before do
    api_connection
      .share_file(google_drive_test_folder_id, tracking_acct, :writer)
  end

  # delete test folder
  after { tear_down_google_drive_test(api_connection) }

  let(:current_account) { create :account, email: user_acct }
  let(:project) { create :project, owner: current_account.user }
  let(:link_to_folder) do
    "https://drive.google.com/drive/folders/#{google_drive_test_folder_id}"
  end

  before do
    sign_in_as current_account
    # and I wait 5 seconds for Google Drive to propagate the sharing settings to
    # the folder's files
    sleep 5 if VCR.current_cassette.recording?
    create :project_setup, link: link_to_folder, project: project
  end

  scenario 'restores removed file' do
    # when I delete the file
    remote_file.delete

    # and force sync the file
    visit profile_project_root_folder_path(project.owner, project)
    click_on remote_subfolder.name
    find('.file-info').click
    click_on 'Force Sync'

    # and commit the file
    click_on 'Files'
    click_on 'Capture Changes'
    fill_in 'Title', with: 'Delete file'
    click_on 'Capture Changes'

    # and restore the file
    click_on 'Revisions'
    within '.revision', text: 'Delete file' do
      click_on 'More'
    end
    within '.revision', text: 'Import Files' do
      click_on 'Restore'
    end

    # then the file should be located in subfolder
    click_on 'Files'
    click_on remote_subfolder.name

    expect(page).to have_text('original name')

    # and be added
    expect(page).to have_css '.file.addition', text: 'original name'
  end

  context 'when parent of file to restore does not exist' do
    scenario 'restores the file to home folder' do
      # when I delete the file
      remote_file.delete
      remote_subfolder.delete

      # and force sync the file & subfolder
      visit profile_project_root_folder_path(project.owner, project)
      click_on 'Files'
      find('.file-info').click
      click_on 'Force Sync'

      # and commit the file
      click_on 'Files'
      click_on 'Capture Changes'
      fill_in 'Title', with: 'Delete subfolder & file'
      click_on 'Capture Changes'

      # and restore the file
      click_on 'Revisions'
      within '.revision', text: 'Delete subfolder & file' do
        within '.file.deletion', text: 'original name deleted from Folder' do
          click_on 'More'
        end
      end
      within '.revision', text: 'Import Files' do
        click_on 'Restore'
      end

      # then the file should be located in root folder
      click_on 'Files'
      expect(page).to have_text('original name')

      # and be added
      expect(page).to have_css '.file.addition', text: 'original name'
    end
  end

  scenario 'restores moved, renamed, and modified file' do
    # when I move the file
    remote_file.relocate(
      to: google_drive_test_folder_id,
      from: remote_subfolder.id
    )

    # and rename the file
    remote_file.rename('new file name')

    # and update the file
    remote_file.update_content('new contents!')

    # and force sync the file
    visit profile_project_root_folder_path(project.owner, project)
    click_on remote_subfolder.name
    find('.file-info').click
    click_on 'Force Sync'

    # and commit the file
    click_on 'Files'
    click_on 'Capture Changes'
    fill_in 'Title', with: 'Change file'
    click_on 'Capture Changes'

    # and restore the file
    click_on 'Revisions'
    within '.revision', text: 'Change file' do
      within '.file.modification', text: 'new file name' do
        click_on 'More'
      end
    end
    within '.revision', text: 'Import Files' do
      click_on 'Restore'
    end

    # then the file should be located in subfolder
    click_on 'Files'
    click_on remote_subfolder.name
    expect(page).to have_text('original name')

    # and be moved, modified, and renamed
    expect(page).to have_css '.file.movement.modification.rename',
                             text: 'original name'
    # and have a new external ID
    expect(project.staged_files.reload.find_by(name: 'original name'))
      .not_to have_attributes(external_id: remote_file.id)
  end

  context 'when remote file is a folder' do
    let(:remote_file_mime_type) { Providers::GoogleDrive::MimeType.document }

    scenario 'it restores the folder' do
      # when I delete the folder
      remote_file.delete

      # and force sync the folder
      visit profile_project_root_folder_path(project.owner, project)
      click_on remote_subfolder.name
      find('.file-info').click
      click_on 'Force Sync'

      # and commit the folder
      click_on 'Files'
      click_on 'Capture Changes'
      fill_in 'Title', with: 'Delete folder'
      click_on 'Capture Changes'

      # and restore the folder
      click_on 'Revisions'
      within '.revision', text: 'Delete folder' do
        click_on 'More'
      end
      within '.revision', text: 'Import Files' do
        click_on 'Restore'
      end

      # then the folder should be located in subfolder
      click_on 'Files'
      click_on remote_subfolder.name

      expect(page).to have_text('original name')

      # and be added
      expect(page).to have_css '.file.addition', text: 'original name'
    end
  end
end
