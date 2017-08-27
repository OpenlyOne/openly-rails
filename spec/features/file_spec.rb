# frozen_string_literal: true

feature 'File' do
  scenario 'User can view file' do
    # given there is a project
    project = create(:project)
    # with a file
    file = project.files.find 'Overview'

    # when I visit the file
    visit "/#{project.owner.to_param}/#{project.to_param}/files/#{file.name}"

    # then I see the file title
    expect(page).to have_text file.name
    # and contents
    expect(page).to have_text file.content
  end

  scenario 'User can edit file' do
    # given there is a project
    project = create(:project)
    # with a file
    file = project.files.find 'Overview'
    # and I am signed in as its owner
    sign_in_as project.owner.account

    # when I visit the edit page for the file
    visit "/#{project.owner.to_param}/#{project.to_param}/files/#{file.name}" \
          '/edit'
    # and fill in new content
    fill_in 'Content',            with: 'My new file content'
    # and fill in a summary of changes
    fill_in 'Summary of changes', with: 'Customize Overview file'
    # and save
    click_on 'Save'

    # then I should be back on page for the file
    expect(page).to have_current_path(
      "/#{project.owner.to_param}/#{project.to_param}/files/#{file.name}"
    )
    # and see the new file content
    expect(page).to have_text 'My new file content'
  end
end
