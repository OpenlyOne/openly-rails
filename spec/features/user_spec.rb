# frozen_string_literal: true

feature 'User' do
  scenario 'User can view user profile' do
    # given there is a user
    user = create(:user)

    # when I visit the user profile
    visit "/users/#{user.id}"

    # then I should see the user's name
    expect(page).to have_text user.name
  end
end
