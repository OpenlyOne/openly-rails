# frozen_string_literal: true

feature 'User' do
  scenario 'User can view user profile' do
    # given there is a user
    user = create(:user)
    # with three projects
    projects = create_list(:project, 3, :skip_archive_setup, owner: user)

    # when I visit the user profile
    visit "/#{user.handle}"

    # then I should see the user's name
    expect(page).to have_text user.name
    # and the user's projects
    projects.each do |project|
      expect(page).to have_text project.title
    end
  end

  scenario 'User can edit user profile' do
    # given there is a user
    user = create(:user)
    # and I am signed in as that user's account
    sign_in_as user.account

    # when I visit my profile
    visit "/#{user.handle}"

    # I should not have a profile picture
    expect(user.picture).not_to be_present

    # and click on edit
    find('a#edit_profile').click
    # and fill in a new name, about, and picture
    fill_in 'profiles_base_name', with: 'My New Name'
    fill_in 'About', with: 'Info about me'
    attach_file(
      'profiles_base[picture]',
      Rails.root.join('spec', 'support', 'fixtures', 'profiles', 'picture.jpg')
    )

    # and save
    click_on 'Save'

    # then I should see my new name
    expect(page).to have_css 'h1', text: 'My New Name'
    expect(page).to have_text 'Info about me'
    # and the picture should be saved
    expect(user.reload.picture).to be_exist
  end
end
