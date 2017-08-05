# frozen_string_literal: true

# Features helper methods
module FeaturesHelper
  # signs in the account
  def sign_in_as(account)
    visit '/login'
    fill_in 'Email', with: account.email
    fill_in 'Password', with: account.password
    click_on 'Log in'
  end
end
