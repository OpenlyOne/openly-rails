# frozen_string_literal: true

feature 'File Update: Adding Files' do
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

  scenario 'File is added' do
    # given there is a project with some files
    files

    # when I add another file on Google Drive
    new_file = build :file_items_base

    allow(GoogleDrive).to receive(:list_changes) do
      Google::Apis::DriveV3::ChangeList.new(
        new_start_page_token: '2',
        changes: [
          build(
            :google_drive_change,
            id: new_file.google_drive_id,
            name: new_file.name,
            parent: project.root_folder.google_drive_id,
            version: 1
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

    # then I should see one added file
    expect(page).to have_text new_file.name
  end
end
