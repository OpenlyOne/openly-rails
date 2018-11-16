# frozen_string_literal: true

feature 'Collaborators: As a collaborator' do
  let(:project) { create(:project, :skip_archive_setup) }

  scenario 'the project is listed on my profile' do
    # given there is a project
    project
    # and I am signed in as a user
    me = create :user
    sign_in_as me.account
    # who is added to that project's Collaborators
    project.collaborators << me

    # when I visit my profile page
    visit me.to_param.to_s

    # then I should see the project
    expect(page).to have_text project.title
  end

  scenario 'I can view a private project' do
    # given there is a project
    project
    # and I am signed in as a user
    me = create :user
    sign_in_as me.account
    # who is added to that project's Collaborators
    project.collaborators << me

    # when I visit the project page
    visit "#{project.owner.to_param}/#{project.to_param}"

    # then I should be on the project's setup page
    expect(page).to have_current_path(
      "/#{project.owner.to_param}/#{project.to_param}/setup/new"
    )
  end

  context 'when project has an archive', :vcr do
    let(:api_connection) do
      Providers::GoogleDrive::ApiConnection.new(owner_acct)
    end
    let(:collaborator_api_connection) do
      Providers::GoogleDrive::ApiConnection.new(collaborator_acct)
    end
    let(:owner_acct)        { ENV['GOOGLE_DRIVE_USER_ACCOUNT'] }
    let(:collaborator_acct) { ENV['GOOGLE_DRIVE_COLLABORATOR_ACCOUNT'] }
    let(:tracking_acct)     { ENV['GOOGLE_DRIVE_TRACKING_ACCOUNT'] }

    # create test folder
    before { prepare_google_drive_test(api_connection) }
    before { refresh_google_drive_authorization(collaborator_api_connection) }
    # with remote file
    let!(:remote_file) do
      Providers::GoogleDrive::FileSync.create(
        name: 'My Google Drive File',
        parent_id: google_drive_test_folder_id,
        mime_type: Providers::GoogleDrive::MimeType.document,
        api_connection: api_connection
      )
    end
    # share test folder
    before do
      api_connection
        .share_file(google_drive_test_folder_id, tracking_acct, :writer)
    end
    # delete test folder
    after { tear_down_google_drive_test(api_connection) }

    let(:collaborator_account)  { create :account, email: collaborator_acct }
    let(:owner_account)         { create :account, email: owner_acct }
    let(:project) { create :project, owner: owner_account.user }
    let(:link_to_folder) do
      "https://drive.google.com/drive/folders/#{google_drive_test_folder_id}"
    end

    before do
      # and I wait 5 seconds for Google Drive to propagate the sharing settings
      # to the folder's files
      sleep 5 if VCR.current_cassette.recording?
      create :project_setup, link: link_to_folder, project: project

      # given I am signed in as a user
      sign_in_as collaborator_account
      # who is added to that project's collaborators
      project.collaborators << collaborator_account.user

      # and I wait 5 seconds for Google Drive to propagate the sharing settings
      # to the folder's files
      sleep 5 if VCR.current_cassette.recording?
    end

    scenario 'I have view access to the archive' do
      # when I visit the project page
      visit "#{project.owner.to_param}/#{project.to_param}"

      # and go to Revisions
      click_on 'Revisions'

      # then I should be able to see the committed files
      anchor_to_archived_file = page.find('a', text: 'My Google Drive File')
      link_to_archived_file = anchor_to_archived_file['href']
      archived_file_id = link_to_archived_file.match(/[-\w]{25,}/)[0]

      # and fetch the committed file
      file =
        Providers::GoogleDrive::FileSync
        .new(archived_file_id, api_connection: collaborator_api_connection)
      expect(file.name).to eq 'My Google Drive File'
    end

    context 'when I am removed as a collaborator' do
      before do
        # remove me as collaborator
        project.collaborators.delete(collaborator_account.user)

        # and I wait 5 seconds for Google Drive to propagate the sharing
        # settings to the folder's files
        sleep 5 if VCR.current_cassette.recording?
      end

      scenario 'I no longer have read access to the archive' do
        # and fetch a file that has been backed up
        backup_id = project.repository.file_backups.first.external_id
        expect { collaborator_api_connection.find_file!(backup_id) }
          .to raise_error(
            Google::Apis::ClientError,
            "notFound: File not found: #{backup_id}."
          )
      end
    end
  end

  scenario 'I can setup a project' do
    # given there is a project
    project
    # and I am signed in as a user
    me = create :user
    sign_in_as me.account
    # who is added to that project's Collaborators
    project.collaborators << me

    # when I visit the project page
    visit "#{project.owner.to_param}/#{project.to_param}"

    # and click on 'Setup'
    click_on 'Setup'

    # then I should be on the setup page
    expect(page).to have_current_path(
      "/#{project.owner.to_param}/#{project.to_param}/setup/new"
    )
  end

  scenario 'I can create a new revision' do
    # given there is a project with complete setup
    project
    create(:project_setup, :completed, project: project)
    # and I am signed in as a user
    me = create :user
    sign_in_as me.account
    # who is added to that project's Collaborators
    project.collaborators << me
    # and the project has some files
    root = create :vcs_staged_file, :root, branch: project.master_branch
    create_list :vcs_staged_file, 5, parent: root

    # when I visit the project page
    visit "#{project.owner.to_param}/#{project.to_param}"
    # and click on Files
    click_on 'Files'
    # and click on Capture Changes
    click_on 'Capture Changes'
    # and enter a revision title
    fill_in 'Title', with: 'Initial Capture'
    # and click on 'Capture'
    click_on 'Capture'

    # then I should be on the project's files page
    expect(page).to have_current_path(
      "/#{project.owner.to_param}/#{project.to_param}/files"
    )
    # and see a success message
    expect(page).to have_text 'Revision successfully created.'
    # and have the revision persisted to the repository
    expect(project.master_branch.commits).to be_any
    # and see no file modification icons
    expect(page).to have_css '.file.no-change', count: 5
  end
end
