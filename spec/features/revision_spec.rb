# frozen_string_literal: true

feature 'Revision' do
  let(:project) { create :project, :setup_complete }
  let(:root)    { create :file_resource, :folder }
  before { project.root_folder = root }
  let(:create_revision) do
    r = project.revisions.create_draft_and_commit_files!(project.owner)
    r.update(is_published: true, title: 'origin revision')
  end

  scenario 'User can see past revisions' do
    # given I am signed in as the project owner
    sign_in_as project.owner.account
    # and there is a file
    file = create :file_resource, name: 'File1', parent: root
    # with three revisions made by three different users
    users = create_list :user, 3
    first_revision = project.revisions.create_draft_and_commit_files!(users[0])
    first_revision.update(is_published: true, title: 'rev1')
    file.update(content_version: 'v2')
    second_revision = project.revisions.create_draft_and_commit_files!(users[1])
    second_revision.update(is_published: true, title: 'rev2')
    file.update(is_deleted: true)
    third_revision = project.revisions.create_draft_and_commit_files!(users[2])
    third_revision.update(is_published: true, title: 'rev3')

    # when I visit the project page
    visit "#{project.owner.to_param}/#{project.to_param}"
    # and click on Revisions
    click_on 'Revisions'

    # then I should see each revision in reverse chronological order
    expect(page.find_all('.revision .metadata .title b').map(&:text))
      .to eq [third_revision, second_revision, first_revision].map(&:title)
    # with their author
    expect(page.find_all('.revision .profile').map(&:text))
      .to eq [users.last.name, users.second.name, users.first.name]
    # and see file changes for each revision
    expect(page.find_all('.revision .name-and-description').map(&:text)).to eq(
      ['File1 deleted from Home', 'File1 modified in Home',
       'File1 added to Home']
    )
  end

  scenario 'User can create revision' do
    # given I am signed in as the project owner
    sign_in_as project.owner.account
    # and the project has some files
    create_list :file_resource, 5, parent: root

    # when I visit the project page
    visit "#{project.owner.to_param}/#{project.to_param}"
    # and click on Files
    click_on 'Files'
    # and click on Capture Changes
    click_on 'Capture Changes'
    # and enter a revision title
    fill_in 'Title', with: 'Initial Capture'
    # and click on 'Capture'
    click_on 'Capture'

    # then I should be on the project's files page
    expect(page).to have_current_path(
      "/#{project.owner.to_param}/#{project.to_param}/files"
    )
    # and see a success message
    expect(page).to have_text 'Revision successfully created.'
    # and have the revision persisted to the repository
    expect(project.revisions.last).to be_present
    # and see no file modification icons
    expect(page).to have_css '.file.unchanged', count: 5
  end

  scenario 'User can review changes' do
    # given there are some files
    create_list :file_resource, 5, name: 'unchanged', parent: root
    folder                      = create :file_resource, :folder, parent: root
    modified_file               = create :file_resource, parent: folder
    moved_out_file              = create :file_resource, parent: folder
    moved_in_file               = create :file_resource, parent: root
    moved_in_and_modified_file  = create :file_resource, parent: root
    removed_file                = create :file_resource, parent: folder
    moved_folder                = create :file_resource, :folder, parent: root
    create_list :file_resource, 5, parent: moved_folder
    # and files are committed
    create_revision
    # and I am signed in as its owner
    sign_in_as project.owner.account

    # when changes are made to files
    added_file = create :file_resource, parent: folder
    modified_file.update(content_version: 'new-version')
    moved_out_file.update(parent: root)
    moved_in_file.update(parent: folder)
    moved_in_and_modified_file.update(parent: folder,
                                      content_version: 'new-v')
    removed_file.update(is_deleted: true)
    moved_folder.update(parent: folder)

    # when I visit the project page
    visit "#{project.owner.to_param}/#{project.to_param}"
    # and click on Files
    click_on 'Files'
    # and click on Capture Changes
    click_on 'Capture Changes'

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
    expect(page).not_to have_text 'unchanged'
  end
end
