# frozen_string_literal: true

feature 'Session' do
  scenario 'User can log in' do
    # given I have an account
    account = create(:account)
    # and I am on the homepage
    visit '/'

    # when I click on 'Login'
    within 'nav' do
      click_on 'Login', exact: true
    end
    # and submit my email and password
    fill_in 'Email', with: account.email
    fill_in 'Password', with: account.password
    click_on 'Log in'

    # then I should be signed in
    expect(page).to have_text 'Signed in successfully'
    # and I should be on my profile page
    expect(page).to have_current_path "/#{account.user.handle}"
  end

  scenario 'User is redirected back after being prompted for authentication' do
    # given I have an account but I am not logged in
    account = create :account

    # when I visit my account settings
    visit edit_account_path
    # and I am prompted to login
    expect(page).to have_current_path new_session_path
    # and I log in
    fill_in 'Email', with: account.email
    fill_in 'Password', with: account.password
    click_on 'Log in'

    # then I should be signed in
    expect(page).to have_text 'Signed in successfully'
    # and I should be back to the account page
    expect(page).to have_current_path edit_account_path
  end

  scenario 'User is redirected back after choosing to log in' do
    # given I have an account but I am not logged in
    account = create :account
    # and there is a project that I want to visit
    project = create :project, owner: account.user

    # when I visit a project page
    visit profile_project_path(project.owner, project)
    # and I click on 'Login'
    within 'nav' do
      click_on 'Login'
    end
    # and I log in
    fill_in 'Email', with: account.email
    fill_in 'Password', with: account.password
    click_on 'Log in'

    # then I should be signed in
    expect(page).to have_text 'Signed in successfully'
    # and I should be back to the project page
    expect(page).to have_current_path(
      profile_project_overview_path(project.owner, project)
    )
  end

  scenario 'User can log out' do
    # given I am a signed-in user
    account = create(:account)
    sign_in_as account
    # and I am on the homepage
    visit '/'

    # when I click on 'Log Out'
    within 'nav' do
      click_on 'Log Out'
    end

    # then I should be signed out
    expect(page).to have_text 'Signed out successfully'
  end

  scenario 'User can choose to be remembered' do
    # given I have an account
    account = create(:account)
    # and I am on the homepage
    visit '/'

    # when I click on 'Login'
    within 'nav' do
      click_on 'Login', exact: true
    end
    # and enter my email and password
    fill_in 'Email', with: account.email
    fill_in 'Password', with: account.password
    # and choose 'Remember me'
    check 'Remember me'
    # and log in
    click_on 'Log in'

    # then I should be signed in
    expect(page).to have_text 'Signed in successfully'
    # and I should be remembered for one week
    expect(account.reload.remember_expires_at)
      .to be_within(1.minute).of(Time.zone.now + 1.week)
  end
end
