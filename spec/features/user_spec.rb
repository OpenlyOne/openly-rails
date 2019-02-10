# frozen_string_literal: true

feature 'User' do
  scenario 'User can view user profile' do
    # given there is a user
    user = create(:user)
    # with three public projects
    projects =
      create_list(:project, 3, :public, :skip_archive_setup, owner: user)

    # when I visit the user profile
    visit "/#{user.handle}"

    # then I should see the user's name
    expect(page).to have_text user.name
    # and the user's projects
    projects.each do |project|
      expect(page).to have_text project.title
    end
  end

  scenario 'User cannot see private projects that they do not collaborate in' do
    me = create(:user)
    sign_in_as me.account

    # given there is a user
    user = create(:user)
    # with two public projects
    public_projects =
      create_list(:project, 2, :public, :skip_archive_setup, owner: user)
    # with two collaboration projects
    collab_projects =
      create_list(:project, 2, :private, :skip_archive_setup, owner: user)
    collab_projects.each do |project|
      project.collaborators << me
    end
    # with two private projects
    private_projects =
      create_list(:project, 2, :private, :skip_archive_setup, owner: user)

    # when I visit the user profile
    visit "/#{user.handle}"

    # then I should see the public and collaboration projects
    (public_projects + collab_projects).each do |project|
      expect(page).to have_link(href: profile_project_path(user, project))
    end

    # but not see the private projects
    private_projects.each do |project|
      expect(page).not_to have_link(href: profile_project_path(user, project))
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
