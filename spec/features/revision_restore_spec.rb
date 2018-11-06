# frozen_string_literal: true

feature 'Revision Restore', :vcr, :delayed_job do
  let(:api_connection)  { Providers::GoogleDrive::ApiConnection.new(user_acct) }
  let(:user_acct)       { ENV['GOOGLE_DRIVE_USER_ACCOUNT'] }
  let(:tracking_acct)   { ENV['GOOGLE_DRIVE_TRACKING_ACCOUNT'] }

  # create test folder
  before { prepare_google_drive_test(api_connection) }

  # delete test folder
  after { tear_down_google_drive_test(api_connection) }

  let(:current_account) { create :account, email: user_acct }
  let(:project) { create :project, owner: current_account.user }
  let(:link_to_folder) do
    "https://drive.google.com/drive/folders/#{google_drive_test_folder_id}"
  end

  scenario 'restores a prior revision' do
    # given_i_have_a_google_drive_project
    fol1 = create_folder(name: 'Fol 1', parent_id: google_drive_test_folder_id)
    fol2 = create_folder(name: 'Fol 2', parent_id: google_drive_test_folder_id)
    fol3 = create_folder(name: 'Fol 3', parent_id: google_drive_test_folder_id)

    file1 = create_file(name: 'File A', parent: fol1, content: 'awesome')
    file2 = create_file(name: 'File B', parent: fol2, content: 'great')
    create_file(name: 'File C', parent: fol2)
    file4 = create_file(name: 'File D', parent: fol3)

    # and_i_share_it_with_the_tracking_account
    api_connection
      .share_file(google_drive_test_folder_id, tracking_acct, :writer)
    sleep 5 if VCR.current_cassette.recording?

    # and_i_set_up_my_project
    create :project_setup, link: link_to_folder, project: project
    Delayed::Worker.new(exit_on_complete: true).work_off
    Delayed::Job.find_each(&:invoke_job)

    # when_i_perform_a_variety_of_actions
    fol2.relocate(to: fol1.id, from: google_drive_test_folder_id)
    fol3.relocate(to: nil, from: google_drive_test_folder_id)
    file4.relocate(to: fol1.id, from: fol3.id)
    file2.delete
    fol1.rename('new folder name')
    file1.update_content('super awesome!')
    create_file(name: 'File E', parent: fol1)
    create_file(name: 'File F', parent_id: google_drive_test_folder_id)

    # and pull each file in stage
    project.master_branch.staged_files.reload.each(&:pull)

    # and pull in new children
    project.master_branch.staged_folders.reload.each(&:pull_children)

    # and go to my project
    sign_in_as current_account
    visit profile_project_path(project.owner, project)

    # and capture changes
    click_on 'Capture Changes'

    # then I should see no changes
    expect(page).not_to have_text 'No files changed'

    # and then go to my initial revision
    click_on 'Revisions'
    click_on 'Import Files'

    # and restore
    click_on 'Restore'

    # then I should see 8 items pending
    expect(page).to have_text('8 files left to restore.', normalize_ws: true)

    # when the jobs process
    Delayed::Worker.new(exit_on_complete: true).work_off

    # and I refresh the page
    click_on 'Refresh'

    # and capture changes
    click_on 'Capture Changes'

    # then I should see no changes
    pending 'Requires implementation of file_content'
    expect(page).to have_text 'No files changed'

    # when I pull each file in stage
    project.master_branch.staged_files.reload.each(&:pull)

    # and pull in new children
    project.master_branch.staged_folders.reload.each(&:pull_children)

    # and capture changes again
    click_on 'Files'
    click_on 'Capture Changes'

    # then I should see no changes
    expect(page).to have_text 'No files changed'
  end

  def create_folder(name:, parent_id:)
    Providers::GoogleDrive::FileSync.create(
      name: name,
      parent_id: parent_id,
      mime_type: Providers::GoogleDrive::MimeType.folder,
      api_connection: api_connection
    )
  end

  def create_file(name:, parent: nil, parent_id: nil, content: nil)
    parent_id ||= parent&.id
    Providers::GoogleDrive::FileSync.create(
      name: name,
      parent_id: parent_id,
      mime_type: Providers::GoogleDrive::MimeType.document,
      api_connection: api_connection
    ).tap do |file|
      file.update_content(content) if content.present?
    end
  end
end
