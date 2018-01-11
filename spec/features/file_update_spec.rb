# frozen_string_literal: true

feature 'File Update' do
  before do
    # avoid infinite loops
    allow_any_instance_of(FileUpdateJob).to receive(:check_for_changes_later)
    allow_any_instance_of(FileUpdateJob).to receive(:list_changes_on_next_page)
  end
  before do
    mock_google_drive_requests if ENV['MOCK_GOOGLE_DRIVE_REQUESTS'] == 'true'
  end

  let(:project) do
    create :project,
           link_to_google_drive_folder: Settings.google_drive_test_folder,
           import_google_drive_folder_on_save: true
  end
  let!(:files)    { create_list :file, 3, parent: project.files.root }
  let(:folder)    { create :file, :folder, parent: project.files.root }
  let!(:subfile)  { create :file, parent: folder }

  # and the files have been committed
  before { create :revision, repository: project.repository }

  scenario 'In Google Drive, user creates file within project folder' do
    # when I create a file in Google Drive within the project folder
    when_i_create_a_file_in_google_drive('My New File', project.files.root_id)

    # and the FileUpdateJob fetches new changes
    FileUpdateJob.perform_later(token: 1)

    # then I should see the file among my project's files
    then_i_should_see_file_in_project(name: 'My New File', status: 'added')
  end

  scenario 'In Google Drive, user updates file metadata' do
    # when I update a file in Google Drive within the project folder
    when_i_update_a_file_in_google_drive(files.first, 'Updated File')

    # and the FileUpdateJob fetches new changes
    FileUpdateJob.perform_later(token: 1)

    # then I should see the file among my project's files
    then_i_should_see_file_in_project(name: 'Updated File', status: 'modified')
  end

  scenario 'In Google Drive, user moves file within project folder' do
    # when I update a file in Google Drive within the project folder
    when_i_move_a_file_in_google_drive(subfile, project.files.root_id)

    # and the FileUpdateJob fetches new changes
    FileUpdateJob.perform_later(token: 1)

    # then I should see the file among my project's files
    then_i_should_see_file_in_project(name: subfile.name, status: 'moved')
  end

  scenario 'In Google Drive, user trashes file' do
    # when I trash a file in Google Drive
    when_i_trash_a_file_in_google_drive(files.first)

    # and the FileUpdateJob fetches new changes
    FileUpdateJob.perform_later(token: 1)

    # then I should see the file among my project's files
    then_i_should_see_file_in_project(name: files.first.name, status: 'deleted')
  end

  scenario 'In Google Drive, user moves file out of project folder' do
    # when I move a file in Google Drive out of project scope
    when_i_move_a_file_in_google_drive(files.first, 'id-outsides-our-scope')

    # and the FileUpdateJob fetches new changes
    FileUpdateJob.perform_later(token: 1)

    # then I should see the file among my project's files
    then_i_should_see_file_in_project(name: files.first.name, status: 'deleted')
  end

  scenario 'In Google Drive, user moves file to the root of their drive' do
    # when I move a file in Google Drive to my root directory
    when_i_move_a_file_in_google_drive(files.first, nil)

    # and the FileUpdateJob fetches new changes
    FileUpdateJob.perform_later(token: 1)

    # then I should see the file among my project's files
    then_i_should_see_file_in_project(name: files.first.name, status: 'deleted')
  end

  scenario 'In Google Drive, user stops sharing file' do
    # when I stop sharing a file in Google Drive
    when_i_stop_sharing_a_file_in_google_drive(files.first)

    # and the FileUpdateJob fetches new changes
    FileUpdateJob.perform_later(token: 1)

    # then I should see the file among my project's files
    then_i_should_see_file_in_project(name: files.first.name, status: 'deleted')
  end

  scenario 'In Google Drive, user deletes the project folder' do
    # when I delete the project folder itself
    when_i_trash_a_file_in_google_drive(project.files.root)

    # and the FileUpdateJob fetches new changes
    FileUpdateJob.perform_later(token: 1)

    # then the folder should not removed
    expect(project.reload.files.root).to be_present
    # and I should be able to see my files and they should be unchanged
    then_i_should_see_file_in_project(name: files.first.name,
                                      status: 'unchanged')
  end

  scenario 'In Google Drive, user deletes a folder within the project folder' do
    # when I delete the project folder itself
    when_i_trash_a_file_in_google_drive(project.files.root)

    # and the FileUpdateJob fetches new changes
    FileUpdateJob.perform_later(token: 1)

    when_i_visit_my_project_files

    # then the folder should not removed
    expect(project.reload.files.root).to be_present
    # and I should be able to see my files and they should be unchanged
    expect(page).not_to have_css '.changed'
  end
end

def mock_google_drive_list_changes(change)
  allow(GoogleDrive).to receive(:list_changes) do
    Google::Apis::DriveV3::ChangeList.new(
      new_start_page_token: '2',
      changes: [change]
    )
  end
end

def then_i_should_see_file_in_project(params)
  when_i_visit_my_project_files
  # then I should see one added file
  expect(page).to have_css ".file.#{params[:status]}", text: params[:name]
end

def when_i_create_a_file_in_google_drive(file_name, folder_id)
  mock_google_drive_list_changes(
    build(:google_drive_change, :with_file, name: file_name, parent: folder_id)
  )
end

def when_i_move_a_file_in_google_drive(file, new_parent_id)
  mock_google_drive_list_changes(
    build(:google_drive_change, :with_file,
          id: file.id,
          name: file.name,
          parent: new_parent_id,
          mime_type: file.mime_type,
          version: file.version + 1)
  )
end

def when_i_stop_sharing_a_file_in_google_drive(file)
  mock_google_drive_list_changes(
    build(:google_drive_change, id: file.id, removed: true)
  )
end

def when_i_trash_a_file_in_google_drive(file)
  mock_google_drive_list_changes(
    build(:google_drive_change, :with_file,
          id: file.id,
          trashed: true,
          mime_type: file.mime_type,
          version: file.version + 1)
  )
end

def when_i_update_a_file_in_google_drive(file, new_name)
  mock_google_drive_list_changes(
    build(:google_drive_change, :with_file,
          id: file.id,
          name: new_name,
          parent: file.parent_id,
          version: file.version + 1,
          modified_time: Time.zone.now.utc)
  )
end

def when_i_visit_my_project_files
  # visit the project page
  visit "#{project.owner.to_param}/#{project.to_param}"
  # click on Files
  click_on 'Files'
end
