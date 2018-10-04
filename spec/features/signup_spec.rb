# frozen_string_literal: true

feature 'Signup' do
  # TODO: Remove all logic related to requesting early access/signup
  scenario 'User can signup' do
    # given I am on the homepage
    visit '/'

    pending 'Signup-related logic should be deleted!'

    # when I enter my email address
    within 'form' do
      fill_in 'signup_email', with: 'someemail@email.com'
      click_on 'Join'
    end

    # then I should see a success message
    expect(page).to have_text 'Thank you. We will be in touch soon'
    # and there should be a signup in the database
    expect(Signup.count).to equal 1
    expect(Signup).to exist(email: 'someemail@email.com')
  end
end
