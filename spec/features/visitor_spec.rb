# frozen_string_literal: true

feature 'Visitors: As a guest/non-collaborator' do
  let(:project) { create(:project, :public, :skip_archive_setup) }

  scenario 'I can view a public project' do
    # given there is a project
    project

    # when I visit the project's owner
    visit "/#{project.owner.to_param}"
    # and click on the project title
    click_on project.title

    # then I should be on the project's overview page
    expect(page).to have_current_path(
      profile_project_overview_path(project.owner, project)
    )
    # and I should see the project's title
    expect(page).to have_text project.title
  end

  context 'when project has an archive', :vcr do
    let(:api_connection) do
      Providers::GoogleDrive::ApiConnection.new(owner_acct)
    end
    let(:guest_api_connection) do
      Providers::GoogleDrive::ApiConnection.new(guest_acct)
    end
    let(:owner_acct)    { ENV['GOOGLE_DRIVE_USER_ACCOUNT'] }
    let(:guest_acct)    { ENV['GOOGLE_DRIVE_COLLABORATOR_ACCOUNT'] }
    let(:tracking_acct) { ENV['GOOGLE_DRIVE_TRACKING_ACCOUNT'] }

    # create test folder
    before { prepare_google_drive_test(api_connection) }
    before { refresh_google_drive_authorization(guest_api_connection) }
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

    let(:guest_account) { create :account, email: guest_acct }
    let(:owner_account) { create :account, email: owner_acct }
    let(:project) { create :project, :public, owner: owner_account.user }
    let(:link_to_folder) do
      "https://drive.google.com/drive/folders/#{google_drive_test_folder_id}"
    end

    before do
      # and I wait 5 seconds for Google Drive to propagate the sharing settings
      # to the folder's files
      sleep 5 if VCR.current_cassette.recording?
      create :project_setup, link: link_to_folder, project: project
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
        .new(archived_file_id, api_connection: guest_api_connection)
      expect(file.name).to eq 'My Google Drive File'
    end

    context 'when project is made private' do
      before do
        project.update!(is_public: false)

        # and I wait 5 seconds for Google Drive to propagate the sharing
        # settings to the folder's files
        sleep 5 if VCR.current_cassette.recording?
      end

      scenario 'I no longer have read access to the archive' do
        # and fetch a file that has been backed up
        backup_id = project.repository.file_backups.first.remote_file_id
        expect { guest_api_connection.find_file!(backup_id) }
          .to raise_error(
            Google::Apis::ClientError,
            "notFound: File not found: #{backup_id}."
          )
      end
    end
  end

  scenario 'I can see the files of the project at its last revision' do
    # given there is a project
    project
    # with completed setup
    create :project_setup, :completed, project: project
    create :vcs_file_in_branch, :root, branch: project.master_branch
    create :vcs_commit, :published, branch: project.master_branch

    # when I visit the project page
    visit "#{project.owner.to_param}/#{project.to_param}"

    # and click on 'Files'
    click_on 'Files'

    # then I should be on the page for the files of the project's last revision
    expect(page).to have_current_path(
      "/#{project.owner.to_param}/#{project.to_param}/" \
      "revisions/#{project.revisions.last.to_param}/files"
    )
    # and see the last commit text
    expect(page).to have_text project.revisions.last.title
  end
end
