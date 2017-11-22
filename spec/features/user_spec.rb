# frozen_string_literal: true

feature 'User' do
  scenario 'User can view user profile' do
    # given there is a user
    user = create(:user)
    # with three projects
    projects = create_list(:project, 3, owner: user)

    # when I visit the user profile
    visit "/#{user.handle}"

    # then I should see the user's name
    expect(page).to have_text user.name
    # and the user's projects
    projects.each do |project|
      expect(page).to have_text project.title
    end
  end
end
