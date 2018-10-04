# frozen_string_literal: true

feature 'Static Pages' do
  scenario 'Visiting the home page' do
    visit '/'
    expect(page).to have_content 'GitHub for Google Drive'
    expect(page).to have_content 'Request Early Access'
  end
end
