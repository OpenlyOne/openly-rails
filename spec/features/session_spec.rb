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
    expect(page).to have_current_path "/#{account.user.username}"
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

  scenario 'User can log out' do
    # given I am a signed-in user
    account = create(:account)
    sign_in_as account
    # and I am on the homepage
    visit '/'

    # when I click on 'Logout'
    within 'nav' do
      click_on 'Logout'
    end

    # then I should be signed out
    expect(page).to have_text 'Signed out successfully'
  end
end
