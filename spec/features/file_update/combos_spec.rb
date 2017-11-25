# frozen_string_literal: true

feature 'File Update: Combining File Actions' do
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

  # rubocop:disable Metrics/MethodLength
  # Add a file with the given name and in the given folder and return the new
  # Google Drive ID
  def add_file(name, folder, folder_type = false)
    new_file =
      if folder_type
        build :file_items_folder, name: name
      else
        build :file_items_base, name: name
      end

    allow(GoogleDrive).to receive(:list_changes) do
      Google::Apis::DriveV3::ChangeList.new(
        new_start_page_token: '2',
        changes: [
          build(
            :google_drive_change,
            id: new_file.google_drive_id,
            name: new_file.name,
            mime_type: new_file.mime_type,
            parent: folder.google_drive_id,
            version: 1
          )
        ]
      )
    end

    new_file.google_drive_id
  end

  # Move a file into the given Google Drive ID
  def move_file(file, parent_id)
    allow(GoogleDrive).to receive(:list_changes) do
      Google::Apis::DriveV3::ChangeList.new(
        new_start_page_token: '2',
        changes: [
          build(
            :google_drive_change,
            id: file.google_drive_id,
            name: file.name,
            parent: parent_id
          )
        ]
      )
    end

    true
  end

  # Remove a file with the given Google Drive ID
  def remove_file(google_drive_id)
    allow(GoogleDrive).to receive(:list_changes) do
      Google::Apis::DriveV3::ChangeList.new(
        new_start_page_token: '2',
        changes: [
          build(
            :google_drive_change,
            id: google_drive_id,
            removed: true
          )
        ]
      )
    end

    true
  end
  # rubocop:enable Metrics/MethodLength

  scenario 'Add file > Delete file' do
    # given there is a project with some files
    files

    # Add file in root folder
    google_drive_id = add_file('My New File', project.root_folder)
    FileUpdateJob.perform_later(token: 1)

    # Remove file
    remove_file(google_drive_id)
    FileUpdateJob.perform_later(token: 1)

    # when I visit the project page
    visit "#{project.owner.to_param}/#{project.to_param}"
    # and click on Files
    click_on 'Files'

    # then I should not see 'My New File'
    expect(page).not_to have_text 'My New File'
    expect(page).not_to have_css '.file.updated'
  end

  scenario 'Add folder > Move item inside > Delete folder' do
    # given there is a project with some files
    files

    # Add subfolder in root folder
    google_drive_id = add_file('My New Folder', project.root_folder, true)
    FileUpdateJob.perform_later(token: 1)

    # Move existing file into new subfolder
    move_file(files.first, google_drive_id)

    # Remove folder
    remove_file(google_drive_id)
    FileUpdateJob.perform_later(token: 1)

    # when I visit the project page
    visit "#{project.owner.to_param}/#{project.to_param}"
    # and click on Files
    click_on 'Files'

    # then I should not see 'My New File'
    expect(page).to have_text files.first.name
    expect(page).not_to have_css '.file.updated'
  end
end
