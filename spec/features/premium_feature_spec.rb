# frozen_string_literal: true

feature 'Premium Users' do
  let(:user_account_email) { ENV['GOOGLE_DRIVE_USER_ACCOUNT'] }
  let(:project_owner) { create(:user, account: user_account) }
  let(:user_account)  { build(:account, :premium, email: user_account_email) }

  # create test folder
  before(:each, :vcr) { prepare_google_drive_test }

  # delete test folder
  after(:each, :vcr) { tear_down_google_drive_test }

  scenario 'Premium user can create private project', :vcr do
    # given I am signed in as its owner
    account = user_account.tap(&:save)
    sign_in_as account

    # when I click on 'New Project'
    within 'nav' do
      click_on 'New Project'
    end
    # and fill in title and slug
    fill_in 'project_title', with: 'My Awesome New Project!'
    find('.private').click
    # and save
    click_on 'Create'

    # then I should be on the project page
    expect(page).to have_current_path(
      "/#{account.user.to_param}/my-awesome-new-project/setup/new"
    )
    # and see the new project's title
    expect(page).to have_text 'My Awesome New Project!'
    # and see a success message
    expect(page).to have_text 'Project successfully created.'
    # and have set up an archive folder on Google Drive
    expect(Project.first.archive).to be_present
    # and a repository and master branch
    expect(Project.first.repository).to be_present
    expect(Project.first.master_branch).to be_present
    # and be private
    expect(Project.first).to be_private
  end
end
