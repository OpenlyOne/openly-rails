# frozen_string_literal: true

require 'support/helpers/settings_helper.rb'
RSpec.configure do |c|
  c.extend SettingsHelper
end

feature 'Account' do
  context 'When registrations are enabled' do
    enable_account_registration

    scenario 'User can create an account' do
      # given I am on the homepage
      visit '/'

      # when I click 'Join'
      within 'nav' do
        click_on 'Join'
      end
      # and enter my email address and password
      account = build(:account)
      within 'form' do
        fill_in 'Username', with: account.user.handle
        fill_in 'Name', with: account.user.name
        fill_in 'Email', with: account.email
        fill_in 'Password', with: account.password, match: :first
        fill_in 'Password confirmation', with: account.password
        click_on 'Join'
      end

      # then I should see a success message
      expect(page).to have_text 'signed up successfully'
      # and there should be an account in the database
      expect(Account.count).to equal 1
      expect(Account).to exist(email: account.email)
      # and there should be a user in the database
      expect(Profiles::User).to exist(account: Account.first)
    end
  end

  scenario 'User can change password' do
    # given I am a signed-in user
    account = create(:account)
    sign_in_as account
    # and I am on the homepage
    visit '/'

    # when I go to the edit account page
    within 'nav' do
      click_on 'Account'
    end
    # and update my password
    fill_in 'Current password', with: account.password
    fill_in 'Password', with: 'newpassword', match: :first
    fill_in 'Password confirmation', with: 'newpassword'
    click_on 'Save'

    # then I should be (remain) on the account page
    expect(page).to have_current_path '/account'
    # and see a success message
    expect(page).to have_text 'updated successfully'
    # and my password should be updated in the database
    expect(account.reload).to be_valid_password('newpassword')
  end

  scenario 'User can delete account' do
    # given I am a signed-in user
    account = create(:account)
    # and have lots of data (this is to test foreign key constraints)
    create_list(:project, 3, owner: account.user)
    # sign in
    sign_in_as account
    # and I am on the homepage
    visit '/'

    # when I go to the edit account page
    within 'nav' do
      click_on 'Account'
    end

    # Disable Bullet because deleting will trigger an N+1 query
    # TODO: Avoid the N+1 query by eager loading records to be deleted
    #       (requires modifying the Devise controllers)
    Bullet.enable = false

    # and click cancel my account
    click_on 'Delete my account'

    # Re-enable Bullet
    Bullet.enable = true

    # then I should see a success message
    expect(page).to have_text 'successfully cancelled'
    # and my account should be deleted from the database
    expect(Account).not_to exist(account.id)
    expect(Account).not_to exist(email: account.email)
    # and so should the user
    expect(Profiles::User).not_to exist(account.user.id)
  end
end
