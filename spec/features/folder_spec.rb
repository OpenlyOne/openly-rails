# frozen_string_literal: true

feature 'Project' do
  scenario 'User can view root-folder' do
    # given there is a project
    project = create :project
    # with some files and folders
    root = create :file_items_folder, project: project, parent: nil
    files = create_list :file_items_base, 5, project: project, parent: root

    # when I visit the project page
    visit "#{project.owner.to_param}/#{project.to_param}"
    # and click on Files
    click_on 'Files'

    # then I should be on the project's files page
    expect(page).to have_current_path(
      "/#{project.owner.to_param}/#{project.to_param}/files"
    )
    # and see the files in the project root folder
    files.each do |file|
      expect(page).to have_text file.name
    end
  end

  scenario 'User can view sub-folder' do
    # given there is a project
    project = create :project
    # with some files and folders
    root = create :file_items_folder, project: project, parent: nil
    create_list :file_items_base, 5, project: project, parent: root
    subfolder = create :file_items_folder, project: project, parent: root
    subfiles =
      create_list :file_items_base, 5, project: project, parent: subfolder

    # when I visit the project page
    visit "#{project.owner.to_param}/#{project.to_param}"
    # and click on Files
    click_on 'Files'
    # and click on the subfolder
    click_on subfolder.name

    # then I should be on the project's subfolder page
    expect(page).to have_current_path(
      "/#{project.owner.to_param}/#{project.to_param}/folders/" \
      "#{subfolder.google_drive_id}"
    )
    # and see the files in the project subfolder
    subfiles.each do |file|
      expect(page).to have_text file.name
    end
  end
end
