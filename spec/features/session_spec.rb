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
  end

  scenario 'User can log out' do
    # given I am a signed-in user
    account = create(:account)
    sign_in account, scope: :account
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
