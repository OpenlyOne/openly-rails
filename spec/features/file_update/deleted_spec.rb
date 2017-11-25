# frozen_string_literal: true

feature 'File Update: Deleting Files' do
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

  scenario 'File is trashed' do
    # given there is a project with some files
    files

    # when I trash the first file on Google Drive
    trashed_file = files.first

    allow(GoogleDrive).to receive(:list_changes) do
      Google::Apis::DriveV3::ChangeList.new(
        new_start_page_token: '2',
        changes: [
          build(
            :google_drive_change,
            id: trashed_file.google_drive_id,
            name: trashed_file.name,
            parent: trashed_file.parent.google_drive_id,
            version: trashed_file.version + 1,
            trashed: true,
            removed: false
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

    # then I should see one modified file
    expect(page).to have_text trashed_file.name
  end

  scenario 'File is removed (e.g. loss of access)' do
    # given there is a project with some files
    files

    # when I remove access to the first file on Google Drive
    removed_file = files.first

    allow(GoogleDrive).to receive(:list_changes) do
      Google::Apis::DriveV3::ChangeList.new(
        new_start_page_token: '2',
        changes: [
          build(
            :google_drive_change_removal,
            id: removed_file.google_drive_id
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
    expect(page).to have_text removed_file.name
  end

  # Ensure that root folder is not destroyed when unshared/removed in Drive
  scenario 'Root folder is removed (e.g. loss of access)' do
    # given there is a project with some files
    files

    # when I remove access to the root folder on Google Drive
    allow(GoogleDrive).to receive(:list_changes) do
      Google::Apis::DriveV3::ChangeList.new(
        new_start_page_token: '2',
        changes: [
          build(
            :google_drive_change_removal,
            id: project.root_folder.google_drive_id
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

    # then I should see no change
    expect(page).not_to have_css '.file.changed'
  end
end
