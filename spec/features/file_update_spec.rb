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

  let(:project) do
    create :project,
           link_to_google_drive_folder: link_to_folder,
           import_google_drive_folder_on_save: true
  end
  let(:link_to_folder) do
    "https://drive.google.com/drive/folders/#{google_drive_test_folder_id}"
  end
  let!(:token) do
    Providers::GoogleDrive::ApiConnection
      .default.start_token_for_listing_changes
  end
  let(:create_revision) do
    r = project.revisions.create_draft_and_commit_files!(project.owner)
    r.update(is_published: true, title: 'origin revision')
  end

  scenario 'In Google Drive, user creates file within project folder' do
    given_project_is_imported_and_changes_committed

    # when I create a file in Google Drive within the project folder
    create_google_drive_file(name: 'My New File',
                             parent_id: google_drive_test_folder_id,
                             api_connection: api_connection)

    wait_for_google_to_propagate_changes
    run_file_update_job

    # then I should see the file among my project's files
    then_i_should_see_file_in_project(name: 'My New File', status: 'added')
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
    then_i_should_see_file_in_project(name: 'File', status: 'modified')
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
    then_i_should_see_file_in_project(name: 'New File Name', status: 'renamed')
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
    then_i_should_see_file_in_project(name: 'File To Move', status: 'moved')
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
    then_i_should_see_file_in_project(name: 'File To Trash', status: 'deleted')
  end

  scenario 'In Google Drive, user deletes file' do
    # given a file within the project folder
    file_to_delete =
      create_google_drive_file(
        name: 'File To Delete',
        parent_id: google_drive_test_folder_id,
        api_connection: api_connection
      )

    given_project_is_imported_and_changes_committed

    # when I delete the file
    api_connection.delete_file(file_to_delete.id)

    wait_for_google_to_propagate_changes
    run_file_update_job

    # then I should see the file among my project's files as deleted
    then_i_should_see_file_in_project(name: 'File To Delete', status: 'deleted')
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
    then_i_should_see_file_in_project(name: 'File To Move', status: 'deleted')

    # cleanup: remove out-of-scope-folder
    api_connection.delete_file(out_of_scope_folder.id)
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
    then_i_should_see_file_in_project(name: 'File To Move', status: 'deleted')

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
    then_i_should_see_file_in_project(name: 'File', status: 'deleted')
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
    then_i_should_see_file_in_project(name: 'File', status: 'deleted')
  end
end

def given_project_is_imported_and_changes_committed
  project
  create_revision
end

def then_i_should_see_file_in_project(params)
  when_i_visit_my_project_files
  # then I should see one added file
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
