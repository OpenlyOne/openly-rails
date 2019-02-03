# frozen_string_literal: true

feature 'Contributions: Acceptances', :vcr do
  let(:api_connection) { Providers::GoogleDrive::ApiConnection.new(user_acct) }
  let(:user_acct)         { ENV['GOOGLE_DRIVE_USER_ACCOUNT'] }
  let(:tracking_acct)     { ENV['GOOGLE_DRIVE_TRACKING_ACCOUNT'] }
  let(:collaborator_acct) { ENV['GOOGLE_DRIVE_COLLABORATOR_ACCOUNT'] }
  let(:contributor_acct)  { ENV['GOOGLE_DRIVE_CONTRIBUTOR_ACCOUNT'] }

  before do
    # create test folder
    prepare_google_drive_test(api_connection)

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

    # with a few suggested changes
    file1_in_contribution = contribution.files.find_by!(name: 'File 1')
    file2_in_contribution = contribution.files.find_by!(name: 'File 2')
    file1_in_contribution.remote.rename('File 1 Updated')
    file2_in_contribution.remote.update_content('cool content')

    # and pull each file in stage
    contribution.files.reload.each(&:pull)

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
    file1_in_master =
      project.master_branch.files.find_by!(name: 'File 1 Updated')
    expect(file1_in_master.remote.name).to eq 'File 1 Updated'
    file2_in_master = project.master_branch.files.find_by!(name: 'File 2')
    expect(file2_in_master.remote.content).to eq 'cool content'

    # and it creates a new commit with contribution title & description
    click_on 'Revisions'
    expect(page).to have_text contribution.creator.name
    expect(page).to have_text contribution.title
    expect(page).to have_text contribution.description
    expect(page).to have_text "File 1 Updated renamed from 'File 1'"
    expect(page).to have_text 'File 2 modified in Home'

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
