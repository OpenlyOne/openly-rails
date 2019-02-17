# frozen_string_literal: true

feature 'Contributions: Acceptances', :vcr do
  let(:api_connection) { Providers::GoogleDrive::ApiConnection.new(user_acct) }
  let(:contributor_api_connection) do
    Providers::GoogleDrive::ApiConnection.new(contributor_acct)
  end
  let(:user_acct)         { ENV['GOOGLE_DRIVE_USER_ACCOUNT'] }
  let(:tracking_acct)     { ENV['GOOGLE_DRIVE_TRACKING_ACCOUNT'] }
  let(:collaborator_acct) { ENV['GOOGLE_DRIVE_COLLABORATOR_ACCOUNT'] }
  let(:contributor_acct)  { ENV['GOOGLE_DRIVE_CONTRIBUTOR_ACCOUNT'] }

  before do
    # create test folder
    prepare_google_drive_test(api_connection)
    refresh_google_drive_authorization(contributor_api_connection)

    # share test folder
    api_connection
      .share_file(google_drive_test_folder_id, tracking_acct, :writer)
  end

  let(:current_account) { create :account, email: user_acct }
  let(:contribution_creator) { create :user, account_email: contributor_acct }
  let(:project) do
    create :project, :public, :with_repository, owner: current_account.user
  end
  let(:link_to_folder) do
    "https://drive.google.com/drive/folders/#{google_drive_test_folder_id}"
  end
  let(:set_up_project) do
    create :project_setup, link: link_to_folder, project: project
  end
  let(:contribution) do
    create :contribution, :setup,
           origin_revision: project.revisions.last,
           creator: contribution_creator, project: project
  end

  scenario 'User can accept suggested changes' do
    # given there is a google drive folder with some files
    create_file(name: 'File 1', parent_id: google_drive_test_folder_id)
    create_file(name: 'File 2', parent_id: google_drive_test_folder_id)

    # and there is a project
    set_up_project

    # with a collaborator
    project.collaborators << create(:user, account_email: collaborator_acct)

    # and a contribution
    contribution

    # and the master has some new changes committed
    file2_in_master = project.files.find_by!(name: 'File 2')
    file2_in_master.remote.update_content('cool content')
    file2_in_master.pull
    create :vcs_commit, :commit_files, parent: project.revisions.last,
                                       branch: project.master_branch

    # and some unsaved changes
    file1_in_master = project.files.find_by!(name: 'File 1')
    file1_in_master.remote.rename('File 1 (new)')
    file2_in_master.remote.rename('File 2 (new)')

    file1_in_master.pull
    file2_in_master.pull

    # and the contribution has suggested changes
    contribution_folder_id = contribution.files.root.remote_file_id
    folder_in_contribution = create_file(
      name: 'Folder',
      mime_type: Providers::GoogleDrive::MimeType.folder,
      parent_id: contribution_folder_id,
      api: contributor_api_connection
    )
    file1_in_contribution = contribution.files.find_by!(name: 'File 1')
    file1_in_contribution.remote.relocate(to: folder_in_contribution.id,
                                          from: contribution_folder_id)
    create_file(name: 'Subfile', parent_id: folder_in_contribution.id,
                api: contributor_api_connection)

    # and pull each file in stage
    contribution.files.root.pull_children
    contribution.files.reload.without_root.folders.each(&:pull_children)
    file1_in_contribution.pull

    # when I go to review the changes
    sign_in_as current_account
    visit profile_project_contribution_review_path(
      project.owner, project, contribution
    )

    # and accept them
    click_on 'Accept Changes'

    # THEN it tells me that files are being updated
    expect(page).to have_text(
      'Contribution successfully accepted. ' \
      'Suggested changes are being applied..'
    )

    # and it marks contribution as accepted
    expect(contribution.reload).to be_accepted

    # and it updates remote files
    folder_in_master = project.files.find_by!(name: 'Folder')
    expect(folder_in_master.remote.name).to eq 'Folder'
    file1_in_master = project.files.find_by!(
      name: 'File 1', parent: folder_in_master.file
    )
    expect(file1_in_master.remote.name).to eq 'File 1'
    expect(file1_in_master.remote.parent_id)
      .to eq folder_in_master.remote_file_id
    file2_in_master = project.files.find_by!(name: 'File 2 (new)')
    expect(file2_in_master.remote.name).to eq 'File 2 (new)'
    expect(file2_in_master.remote.content).to eq 'cool content'
    subfile_in_master = project.files.find_by!(
      name: 'Subfile', parent: folder_in_master.file
    )
    expect(subfile_in_master.remote.name).to eq 'Subfile'
    expect(subfile_in_master.remote.parent_id)
      .to eq folder_in_master.remote_file_id

    # it has one uncaptured change
    expect(project.reload.uncaptured_changes_count).to eq 1

    # and it creates a new commit with contribution title & description
    click_on 'Revisions'
    within ".revision[id='#{project.revisions.reload.last.id}']" do
      expect(page).to have_text contribution.creator.name
      expect(page).to have_text contribution.title
      expect(page).to have_text contribution.description
      expect(page).to have_text 'Folder added to Home'
      expect(page).to have_text 'Subfile added to Folder'
      expect(page).to have_text 'File 1 moved to Folder'
      expect(page).not_to have_text 'File 1 renamed'
      expect(page).not_to have_text 'File 2'
    end

    # TODO: it emails the contribution creator and my fellow project maintainers
  end
end

def create_revision(title)
  c = master_branch.commits.create_draft_and_commit_files!(project.owner)
  c.update!(is_published: true, title: title)
end

# Return the forked FileInBranch instance in the contribution
def in_contribution(file)
  contribution.files.find_by!(file_id: file.file_id)
end

def create_file(name:, parent_id: nil, content: nil, mime_type: nil, api: nil)
  Providers::GoogleDrive::FileSync.create(
    name: name,
    parent_id: parent_id,
    mime_type: mime_type || Providers::GoogleDrive::MimeType.document,
    api_connection: api || api_connection
  ).tap do |file|
    file.update_content(content) if content.present?
  end
end
