# frozen_string_literal: true

feature 'File Update: Moving Files' do
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
  let(:files) { project.root_folder.children }

  scenario 'File is moved to subfolder' do
    # given there is a project with some files
    files
    # and a subfolder
    subfolder = create :file_items_folder,
                       project: project,
                       parent: project.root_folder

    # when I move the first file on Google Drive
    moved_file = files.first

    allow(GoogleDrive).to receive(:list_changes) do
      Google::Apis::DriveV3::ChangeList.new(
        new_start_page_token: '2',
        changes: [
          build(
            :google_drive_change,
            id: moved_file.google_drive_id,
            name: moved_file.name,
            parent: subfolder.google_drive_id,
            version: moved_file.version + 1,
            modified_time: moved_file.modified_time
          )
        ]
      )
    end

    # and the FileUpdateJob fetches new changes
    FileUpdateJob.perform_later(token: 1)

    # when I visit the project page
    visit "#{project.owner.to_param}/#{project.to_param}"
    # and click on Files
    click_on 'Files'
    # and click on the subfolder
    click_on subfolder.name

    # then I should see one moved file
    within '.file.moved' do
      expect(page).to have_text moved_file.name
    end
  end

  scenario 'File is moved out of project scope (no-parent)' do
    # given there is a project with some files
    files

    # when I move the first file on Google Drive
    moved_file = files.first

    allow(GoogleDrive).to receive(:list_changes) do
      Google::Apis::DriveV3::ChangeList.new(
        new_start_page_token: '2',
        changes: [
          build(
            :google_drive_change,
            id: moved_file.google_drive_id,
            name: moved_file.name,
            parent: nil,
            version: moved_file.version + 1
          )
        ]
      )
    end

    # and the FileUpdateJob fetches new changes
    FileUpdateJob.perform_later(token: 1)

    # when I visit the project page
    visit "#{project.owner.to_param}/#{project.to_param}"
    # and click on Files
    click_on 'Files'

    # then I should see one deleted file
    within '.file.deleted' do
      expect(page).to have_text moved_file.name
    end
  end

  scenario 'File is moved out of project scope (unrecognized-parent)' do
    # given there is a project with some files
    files

    # when I move the first file on Google Drive
    moved_file = files.first

    allow(GoogleDrive).to receive(:list_changes) do
      Google::Apis::DriveV3::ChangeList.new(
        new_start_page_token: '2',
        changes: [
          build(
            :google_drive_change,
            id: moved_file.google_drive_id,
            name: moved_file.name,
            parent: 'abc',
            version: moved_file.version + 1
          )
        ]
      )
    end

    # and the FileUpdateJob fetches new changes
    FileUpdateJob.perform_later(token: 1)

    # when I visit the project page
    visit "#{project.owner.to_param}/#{project.to_param}"
    # and click on Files
    click_on 'Files'

    # then I should see one deleted file
    within '.file.deleted' do
      expect(page).to have_text moved_file.name
    end
  end
end
