# frozen_string_literal: true

feature 'File Update', :vcr do
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

  before do
    # avoid infinite loops
    allow_any_instance_of(FileUpdateJob).to receive(:check_for_changes_later)
    allow_any_instance_of(FileUpdateJob).to receive(:list_changes_on_next_page)
  end

  let(:current_account) { create :account, email: user_acct }
  let(:project) { create :project, owner: current_account.user }
  let(:setup) { create :project_setup, link: link_to_folder, project: project }
  let(:link_to_folder) do
    "https://drive.google.com/drive/folders/#{google_drive_test_folder_id}"
  end
  let!(:token) do
    Providers::GoogleDrive::ApiConnection
      .default.start_token_for_listing_changes
  end

  before { sign_in_as current_account }

  scenario 'In Google Drive, user creates file within project folder' do
    given_project_is_imported_and_changes_committed

    # when I create a file in Google Drive within the project folder
    file = create_google_drive_file(name: 'My New File',
                                    parent_id: google_drive_test_folder_id,
                                    api_connection: api_connection)

    wait_for_google_to_propagate_changes
    run_file_update_job

    # then I should see the file among my project's files
    then_i_should_see_file_in_project(name: 'My New File', status: 'addition')
    # and have a backup of the file snapshot
    staged = project.staged_files.find_by_remote_file_id(file.id)
    and_have_a_backup_of_file_snapshot(staged.current_snapshot)
  end

  scenario 'In Google Drive, user updates file content' do
    # given a file within the project folder
    file_to_modify =
      create_google_drive_file(
        name: 'File',
        parent_id: google_drive_test_folder_id,
        api_connection: api_connection
      )

    given_project_is_imported_and_changes_committed

    # when I update the file contents
    api_connection.update_file_content(file_to_modify.id, 'new file content')

    wait_for_google_to_propagate_changes
    run_file_update_job

    # then I should see the file among my project's files as modified
    then_i_should_see_file_in_project(name: 'File', status: 'modification')

    # and have a backup of the file snapshot as it is now
    staged = project.staged_files.find_by_remote_file_id(file_to_modify.id)
    and_have_a_backup_of_file_snapshot(staged.current_snapshot)

    # and have a backup of the file snapshot as it was before
    and_have_a_backup_of_file_snapshot(staged.file_record.file_snapshots.first)
  end

  scenario 'In Google Drive, user renames file' do
    # given a file within the project folder
    file_to_rename =
      create_google_drive_file(
        name: 'File',
        parent_id: google_drive_test_folder_id,
        api_connection: api_connection
      )

    given_project_is_imported_and_changes_committed

    # when I rename the file
    file_to_rename.rename('New File Name')

    wait_for_google_to_propagate_changes
    run_file_update_job

    # then I should see the file among my project's files as modified
    then_i_should_see_file_in_project(name: 'New File Name', status: 'rename')

    # and have a backup of the file snapshot as it is now
    staged = project.staged_files.find_by_remote_file_id(file_to_rename.id)
    and_have_a_backup_of_file_snapshot(staged.current_snapshot)

    # and have a backup of the file snapshot as it was before
    and_have_a_backup_of_file_snapshot(staged.file_record.file_snapshots.first)
  end

  scenario 'In Google Drive, user moves file within project folder' do
    # given a file & folder within the project folder
    folder =
      create_google_drive_file(
        name: 'Folder',
        parent_id: google_drive_test_folder_id,
        mime_type: Providers::GoogleDrive::MimeType.folder,
        api_connection: api_connection
      )
    file_to_move =
      create_google_drive_file(
        name: 'File To Move',
        parent_id: folder.id,
        api_connection: api_connection
      )

    given_project_is_imported_and_changes_committed

    # when I update a file in Google Drive within the project folder
    file_to_move.relocate(from: folder.id,
                          to: google_drive_test_folder_id)

    wait_for_google_to_propagate_changes
    run_file_update_job

    # then I should see the file among my project's files
    then_i_should_see_file_in_project(name: 'File To Move', status: 'movement')
  end

  scenario 'In Google Drive, user trashes file' do
    # given a file within the project folder
    file_to_trash =
      create_google_drive_file(
        name: 'File To Trash',
        parent_id: google_drive_test_folder_id,
        api_connection: api_connection
      )

    given_project_is_imported_and_changes_committed

    # when I trash the file
    api_connection.trash_file(file_to_trash.id)

    wait_for_google_to_propagate_changes
    run_file_update_job

    # then I should see the file among my project's files as deleted
    then_i_should_see_file_in_project(name: 'File To Trash', status: 'deletion')
  end

  scenario 'In Google Drive, user deletes file' do
    # given a file within the project folder
    file_to_delete =
      create_google_drive_file(
        name: 'To Delete',
        parent_id: google_drive_test_folder_id,
        api_connection: api_connection
      )

    given_project_is_imported_and_changes_committed

    # when I delete the file
    api_connection.delete_file(file_to_delete.id)

    wait_for_google_to_propagate_changes
    run_file_update_job

    # then I should see the file among my project's files as deleted
    then_i_should_see_file_in_project(name: 'To Delete', status: 'deletion')
  end

  scenario 'In Google Drive, user moves file out of project folder' do
    # given a file within the project folder
    file_to_move =
      create_google_drive_file(
        name: 'File To Move',
        parent_id: google_drive_test_folder_id,
        api_connection: api_connection
      )

    given_project_is_imported_and_changes_committed

    # create a folder in the user's home
    out_of_scope_folder =
      api_connection.create_file_in_home_folder(
        name: 'out-of-scope-folder',
        mime_type: Providers::GoogleDrive::MimeType.folder
      )

    # when I move a file in Google Drive out of project scope
    file_to_move.relocate(from: google_drive_test_folder_id,
                          to: out_of_scope_folder.id)

    wait_for_google_to_propagate_changes
    run_file_update_job

    # then I should see the file among my project's files
    then_i_should_see_file_in_project(name: 'File To Move', status: 'deletion')

    # cleanup: remove out-of-scope-folder
    api_connection.delete_file(out_of_scope_folder.id)
  end

  xscenario 'In Google Drive, user moves file from one repository to another' do
    # TODO: Add scenario: User moves folder/file from one repository to another
  end

  scenario 'In Google Drive, user moves file to the root of their drive' do
    # given a file within the project folder
    file_to_move =
      create_google_drive_file(
        name: 'File To Move',
        parent_id: google_drive_test_folder_id,
        api_connection: api_connection
      )

    given_project_is_imported_and_changes_committed

    # when I move a file in Google Drive to my root directory
    file_to_move.relocate(from: google_drive_test_folder_id, to: 'root')

    wait_for_google_to_propagate_changes
    run_file_update_job

    # then I should see the file among my project's files
    then_i_should_see_file_in_project(name: 'File To Move', status: 'deletion')

    # cleanup: remove moved file
    api_connection.delete_file(file_to_move.id)
  end

  scenario 'In Google Drive, user stops sharing file' do
    # given a file within the project folder
    file_to_unshare = create_google_drive_file(
      name: 'File',
      parent_id: google_drive_test_folder_id,
      api_connection: api_connection
    )

    given_project_is_imported_and_changes_committed

    # when I unshare the file
    api_connection.unshare_file(file_to_unshare.id,
                                ENV['GOOGLE_DRIVE_TRACKING_ACCOUNT'])

    wait_for_google_to_propagate_changes
    run_file_update_job

    # then the file should be marked as unshared
    then_i_should_see_file_in_project(name: 'File', status: 'deletion')
  end

  scenario 'In Google Drive, user deletes the project folder' do
    # given a file within the project folder
    create_google_drive_file(
      name: 'File',
      parent_id: google_drive_test_folder_id,
      api_connection: api_connection
    )

    given_project_is_imported_and_changes_committed

    # when I delete the project folder
    delete_google_drive_test_folder(api_connection)

    wait_for_google_to_propagate_changes
    run_file_update_job

    # then all files should be marked as deleted
    then_i_should_see_file_in_project(name: 'File', status: 'deletion')
  end
end

# rubocop:disable Metrics/AbcSize
# TODO: Reduce complexity
def and_have_a_backup_of_file_snapshot(file_snapshot)
  remote_file_id_of_backup = file_snapshot.backup.remote_file_id
  external_backup =
    Providers::GoogleDrive::FileSync.new(remote_file_id_of_backup)
  expect(external_backup.name).to eq(file_snapshot.name)
  expect(external_backup.parent_id)
    .to eq(project.archive.remote_file_id)
end
# rubocop:enable Metrics/AbcSize

def given_project_is_imported_and_changes_committed
  setup
end

def then_i_should_see_file_in_project(params)
  when_i_visit_my_project_files
  # then I should see one file with the given status
  expect(page).to have_css ".file.#{params[:status]}", text: params[:name]
end

def run_file_update_job
  FileUpdateJob.perform_later(token: token)
end

def wait_for_google_to_propagate_changes
  sleep 60 if VCR.current_cassette.recording?
end

def when_i_visit_my_project_files
  # visit the project page
  visit "#{project.owner.to_param}/#{project.to_param}"
  # click on Files
  click_on 'Files'
end
