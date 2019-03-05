# frozen_string_literal: true

feature 'Static Pages' do
  scenario 'Visiting the home page' do
    visit '/'
    expect(page).to have_content(
      "It's time to tackle the world's biggest challenges."
    )
    expect(page).to have_link 'Join Us'
  end

  scenario 'User can visit the platform landing page' do
    visit '/platform'
    expect(page).to have_content 'Work on documents just like you do on code'
    expect(page).to have_link 'Get Started'
  end
end
