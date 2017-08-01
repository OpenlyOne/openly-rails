# frozen_string_literal: true

feature 'Session' do
  scenario 'User can log in' do
    # given I have an account
    account = create(:account)

    # when I visit the login page
    visit '/login'
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

    # when I visit the logout page
    visit '/logout'

    # then I should be signed out
    expect(page).to have_text 'Signed out successfully'
  end
end
