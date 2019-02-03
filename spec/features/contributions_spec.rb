# frozen_string_literal: true

feature 'Contributions', :vcr do
  let(:api_connection)              { api_klass.new(user_acct) }
  let(:collaborator_api_connection) { api_klass.new(collaborator_acct) }
  let(:api_klass)         { Providers::GoogleDrive::ApiConnection }
  let(:user_acct)         { ENV['GOOGLE_DRIVE_USER_ACCOUNT'] }
  let(:tracking_acct)     { ENV['GOOGLE_DRIVE_TRACKING_ACCOUNT'] }
  let(:collaborator_acct) { ENV['GOOGLE_DRIVE_COLLABORATOR_ACCOUNT'] }

  # create test folder
  before { prepare_google_drive_test(api_connection) }
  before { refresh_google_drive_authorization(collaborator_api_connection) }

  # share test folder
  before do
    api_connection
      .share_file(google_drive_test_folder_id, tracking_acct, :writer)
  end

  # delete test folder
  after { tear_down_google_drive_test(api_connection) }

  let(:current_account)       { create :account, email: user_acct }
  let(:collaborator_account)  { create :account, email: collaborator_acct }
  let(:project) do
    create :project, :with_repository, owner: current_account.user
  end
  let(:link_to_folder) do
    "https://drive.google.com/drive/folders/#{google_drive_test_folder_id}"
  end
  let(:set_up_project) do
    create :project_setup, link: link_to_folder, project: project
  end

  scenario 'User can see contributions' do
    # given I am signed in as the project owner
    sign_in_as project.owner.account
    # and my project is set up
    set_up_project
    # and there are contributions
    contributions = create_list :contribution, 3, project: project

    # when I visit the project page
    visit "#{project.owner.to_param}/#{project.to_param}"
    # and click on Contributions
    click_on 'Contributions'

    # then I should see each contribution in reverse chronological order
    expect(page.find_all('.contribution .title b').map(&:text))
      .to eq contributions.reverse.map(&:title)
  end

  scenario 'User can create contribution' do
    # given there is a project with a collaborator
    project.collaborators << collaborator_account.user

    # and I am signed in as the collaborator
    sign_in_as collaborator_account

    # and the project has three files
    folder =
      create_folder(name: 'Folder', parent_id: google_drive_test_folder_id)
    file1 = create_file(name: 'File 1', parent: folder)
    file2 = create_file(name: 'File 2', parent: folder)

    # and my project is set up
    set_up_project

    # and the project has one uncaptured file change
    create_file(name: 'File 3', parent_id: google_drive_test_folder_id)

    # when I visit the project page
    visit "#{project.owner.to_param}/#{project.to_param}"
    # and click on Contributions
    click_on 'Contributions'
    # and click on New Contribution
    click_on 'New Contribution'
    # and enter a contribution title
    fill_in 'Title', with: 'A Contribution'
    fill_in 'Description', with: 'My new contribution'
    # and click on 'Create Contribution'
    click_on 'Create Contribution'

    contribution = project.contributions.first

    # then I should be on the contribution page
    expect(page).to have_current_path(
      "/#{project.owner.to_param}/#{project.to_param}" \
      "/contributions/#{contribution.to_param}"
    )
    # and see a success message
    expect(page).to have_text 'Contribution successfully created.'

    # and have copied the three files
    expect(contribution.branch.files.without_root.map(&:name))
      .to contain_exactly(folder.name, file1.name, file2.name)

    # and have edit access to the new branch root
    remote = contribution.branch.root.remote
    remote.switch_api_connection(collaborator_api_connection)
    expect(remote.reload).to be_can_edit

    # and others in the project have view access to the files
    remote.switch_api_connection(api_connection)
    expect(remote.reload).to be_can_read
  end

  # TODO: Extract into shared context because revision_restore_spec uses these
  # =>    exact methods
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
