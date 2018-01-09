# frozen_string_literal: true

feature 'Revision' do
  scenario 'User can create revision' do
    # given there is a project
    project = create :project
    # and I am signed in as its owner
    sign_in_as project.owner.account
    # with some files and folders
    root = create :file, :root, repository: project.repository
    create_list :file, 5, parent: root

    # when I visit the project page
    visit "#{project.owner.to_param}/#{project.to_param}"
    # and click on Filess
    click_on 'Files'
    # and click on Commit Changes
    click_on 'Commit Changes'
    # and enter a revision title
    fill_in 'Title', with: 'Initial Commit'
    # and click on 'Commit'
    click_on 'Commit'

    # then I should be on the project's files page
    expect(page).to have_current_path(
      "/#{project.owner.to_param}/#{project.to_param}/files"
    )
    # and see a success message
    expect(page).to have_text 'Revision successfully created.'
    # and have the revision persisted to the repository
    expect(project.repository.revisions.last).to be_present
    # and see no file modification icons
    expect(page).to have_css '.file.unchanged', count: 5
  end

  scenario 'User can review changes' do
    # given there is a project
    project = create :project
    # with some files and folders
    root = create :file, :root, repository: project.repository
    create_list :file, 5, parent: root
    folder                      = create :file, :folder, parent: root
    modified_file               = create :file, parent: folder
    moved_out_file              = create :file, parent: folder
    moved_in_file               = create :file, parent: root
    moved_in_and_modified_file  = create :file, parent: root
    removed_file                = create :file, parent: folder
    moved_folder                = create :file, :folder, parent: root
    create_list :file, 5, parent: moved_folder
    # and files are committed
    create :revision, repository: project.repository
    # and I am signed in as its owner
    sign_in_as project.owner.account

    # when changes are made to files
    added_file = create :file, parent: folder
    modified_file.update(modified_time: Time.zone.now)
    moved_out_file.update(parent_id: root.id)
    moved_in_file.update(parent_id: folder.id)
    moved_in_and_modified_file.update(parent_id: folder.id,
                                      modified_time: Time.zone.now)
    removed_file.update(parent_id: nil)
    moved_folder.update(parent_id: folder.id)

    # when I visit the project page
    visit "#{project.owner.to_param}/#{project.to_param}"
    # and click on Files
    click_on 'Files'
    # and click on Commit Changes
    click_on 'Commit Changes'

    # then I can see the changes I am about to commit
    expect(page).to have_css '.file.added',     text: added_file.name
    expect(page).to have_css '.file.modified',  text: modified_file.name
    expect(page).to have_css '.file.moved',     text: moved_out_file.name
    expect(page).to have_css '.file.moved',     text: moved_in_file.name
    expect(page).to have_css '.file.moved',
                             text: moved_in_and_modified_file.name
    expect(page).to have_css '.file.modified',
                             text: moved_in_and_modified_file.name
    expect(page).to have_css '.file.deleted', text: removed_file.name
    expect(page).to have_css '.file.moved',   text: moved_folder.name
    # and not see the descendants of moved folders listed
    moved_folder.children.each do |child|
      expect(page).not_to have_text child.name
    end
  end
end
