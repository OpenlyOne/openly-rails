# frozen_string_literal: true

feature 'Static Pages' do
  scenario 'Visiting the home page' do
    visit '/'
    expect(page).to have_content 'Work on documents just like you do on code.'
    expect(page).to have_link 'Join Waitlist'
  end
end
