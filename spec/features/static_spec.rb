# frozen_string_literal: true

feature 'Static Pages' do
  scenario 'Visiting the home page' do
    visit '/'
    expect(page).to have_content 'Create Change Together'
    expect(page).to have_content 'Coming Soon'
  end
end
