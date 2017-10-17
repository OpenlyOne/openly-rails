# frozen_string_literal: true

feature 'File' do
  scenario 'User can list files' do
    # given there is a project
    project = create(:project)
    # with three files (in addition to Overview)
    files = create_list(:vc_file, 3, collection: project.files)
    files.unshift project.files.find('Overview')

    # when I visit the project
    visit profile_project_path(project.owner, project)
    # and click on files
    click_on 'Files'

    # then I should see the four files
    files.each do |file|
      expect(page).to have_link(
        file.name,
        href: profile_project_file_path(project.owner, project, file)
      )
    end
  end

  scenario 'User can create file' do
    # given there is a project
    project = create(:project)
    # and I am signed in as its owner
    sign_in_as project.owner.account

    # when I visit the project's files
    visit profile_project_files_path(project.owner, project)
    # and click on add
    find('a#new-project-file').click
    # and fill in name, content, and revision summary
    fill_in 'File Name',          with: 'My New File'
    fill_in 'Content',            with: 'Lorem ipsum'
    fill_in 'Summary of changes', with: 'Update file name'
    # and create the file
    click_on 'Create'

    # then I should be on the file page
    expect(page).to have_current_path(
      profile_project_file_path(project.owner, project, 'My New File')
    )
    # and see the new file's name
    expect(page).to have_text 'My New File'
    # and see the content
    expect(page).to have_text 'Lorem ipsum'
    # and there should be one more file in the project repository
    expect { project.files.reload! }.to change project.files, :count
  end

  scenario 'User can view file' do
    # given there is a project
    project = create(:project)
    # with a file
    file = project.files.find 'Overview'

    # when I visit the project
    visit profile_project_path(project.owner, project)
    # and click on files
    click_on 'Files'
    # and click on the file
    within find('h5', text: file.name).find(:xpath, '../..') do
      click_on file.name
    end

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

    # when I visit the project
    visit profile_project_path(project.owner, project)
    # and click on files
    click_on 'Files'
    # and click on the file
    within find('h5', text: file.name).find(:xpath, '../..') do
      click_on file.name
    end
    # and click on the edit button
    click_on 'edit-file'
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

  scenario 'User can rename file' do
    # given there is a project
    project = create(:project)
    # with a file
    file = create(:vc_file, collection: project.files)
    # and I am signed in as its owner
    sign_in_as project.owner.account

    # when I visit the project
    visit profile_project_path(project.owner, project)
    # and click on files
    click_on 'Files'
    # and click on the file
    within find('h5', text: file.name).find(:xpath, '../..') do
      click_on file.name
    end
    # and click on the rename button
    click_on 'rename-file'
    # and fill in new content
    fill_in 'File Name',          with: 'My New File'
    # and fill in a summary of changes
    fill_in 'Summary of changes', with: 'Update file name'
    # and save
    click_on 'Rename'

    # then I should be back on page for the file
    expect(page).to have_current_path(
      "/#{project.owner.to_param}/#{project.to_param}/files/My New File"
    )
    # and see the new file content
    expect(page).to have_text 'My New File'
  end

  scenario 'User can delete file' do
    # given there is a project
    project = create(:project)
    # with a file
    file = create(:vc_file, collection: project.files)
    # and I am signed in as its owner
    sign_in_as project.owner.account

    # when I visit the project
    visit profile_project_path(project.owner, project)
    # and click on files
    click_on 'Files'
    # and click on the file
    within find('h5', text: file.name).find(:xpath, '../..') do
      click_on file.name
    end
    # and click on the delete button
    click_on 'delete-file'
    # and fill in a summary of changes
    fill_in 'Summary of changes', with: 'Remove file'
    # and save
    click_on 'Delete'

    # then I should be back on the page for files
    expect(page).to have_current_path(
      profile_project_files_path(project.owner, project)
    )
    # and no longer see the file name listed
    expect(page).not_to have_text file.name
    # and see a notice that the file was deleted
    expect(page).to have_text 'File successfully deleted.'
  end
end
