# frozen_string_literal: true

feature 'Revision' do
  let(:project)       { create :project, :setup_complete, :skip_archive_setup }
  let(:master_branch) { project.master_branch }
  let!(:root) { create :vcs_file_in_branch, :root, branch: master_branch }
  let(:create_revision) do
    c = master_branch.commits.create_draft_and_commit_files!(project.owner)
    c.update(is_published: true, title: 'origin revision')
  end

  scenario 'User can see past revisions' do
    # given I am signed in as the project owner
    sign_in_as project.owner.account
    # and there is a file
    file = create :vcs_file_in_branch, name: 'File1', parent_in_branch: root
    # with three revisions made by three different users
    users = create_list :user, 3
    commit1 = master_branch.commits.create_draft_and_commit_files!(users[0])
    commit1.update(is_published: true, title: 'rev1')
    file.update(content_version: 'v2')
    commit2 = master_branch.commits.create_draft_and_commit_files!(users[1])
    commit2.update(is_published: true, title: 'rev2')
    file.update(is_deleted: true)
    commit3 = master_branch.commits.create_draft_and_commit_files!(users[2])
    commit3.update(is_published: true, title: 'rev3')

    # when I visit the project page
    visit "#{project.owner.to_param}/#{project.to_param}"
    # and click on Revisions
    click_on 'Revisions'

    # then I should see each revision in reverse chronological order
    expect(page.find_all('.revision .metadata .title b').map(&:text))
      .to eq [commit3, commit2, commit1].map(&:title)
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
    create_list :vcs_file_in_branch, 5, parent_in_branch: root

    # when I visit the project page
    visit "#{project.owner.to_param}/#{project.to_param}"
    # and click on Files
    click_on 'Files'
    # and click on Capture Changes
    click_on 'Capture Changes5'
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
    expect(master_branch.commits.last).to be_present
    # and see no file modification icons
    expect(page).to have_css '.file.no-change', count: 5
    expect(page).to have_text 'Capture Changes0'
  end

  context 'Selective capture' do
    let(:unchanged) do
      create_list :vcs_file_in_branch, 2,
                  name: 'unchanged', parent_in_branch: root
    end
    let(:folder) { create :vcs_file_in_branch, :folder, parent_in_branch: root }
    let(:added_file)    { create :vcs_file_in_branch, parent_in_branch: folder }
    let(:modified_file) { create :vcs_file_in_branch, parent_in_branch: folder }
    let(:moved_out_file) do
      create :vcs_file_in_branch, parent_in_branch: folder
    end
    let(:moved_in_file) { create :vcs_file_in_branch, parent_in_branch: root }
    let(:moved_in_and_modified_file) do
      create :vcs_file_in_branch, parent_in_branch: root
    end
    let(:removed_file) { create :vcs_file_in_branch, parent_in_branch: folder }
    let(:moved_folder) do
      create :vcs_file_in_branch, :folder, parent_in_branch: root
    end
    let(:in_moved_folder) do
      create_list :vcs_file_in_branch, 2, parent_in_branch: moved_folder
    end

    scenario 'User can review changes' do
      # given there are files and they are committed in a project
      _files = [
        unchanged, folder, modified_file, moved_out_file, moved_in_file,
        moved_in_and_modified_file, removed_file, moved_folder, in_moved_folder
      ]
      create_revision
      # and I am signed in as its owner
      sign_in_as project.owner.account

      # when changes are made to files
      added_file
      modified_file.update(content_version: 'new-version')
      moved_out_file.update(parent_in_branch: root)
      moved_in_file.update(parent_in_branch: folder)
      moved_in_and_modified_file.update(parent_in_branch: folder,
                                        content_version: 'new-v')
      removed_file.update(is_deleted: true)
      moved_folder.update(parent_in_branch: folder)

      # when I visit the project page
      visit "#{project.owner.to_param}/#{project.to_param}"
      # and click on Files
      click_on 'Files'
      # and click on Capture Changes
      click_on 'Capture Changes7'

      # then I can see the changes I am about to commit
      expect(page).to have_css '.file.addition',      text: added_file.name
      expect(page).to have_css '.file.modification',  text: modified_file.name
      expect(page).to have_css '.file.movement',      text: moved_out_file.name
      expect(page).to have_css '.file.movement',      text: moved_in_file.name
      expect(page).to have_css '.file.movement',
                               text: moved_in_and_modified_file.name
      expect(page).to have_css '.file.modification',
                               text: moved_in_and_modified_file.name
      expect(page).to have_css '.file.deletion',      text: removed_file.name
      expect(page).to have_css '.file.movement',      text: moved_folder.name
      # and not see the descendants of moved folders listed
      expect(page).not_to have_text 'unchanged'
    end

    scenario 'User can unselect all changes' do
      # given there are files and they are committed in a project
      _files = [unchanged, folder, moved_in_and_modified_file, removed_file]
      create_revision
      # and I am signed in as its owner
      sign_in_as project.owner.account

      # when changes are made to files
      added_file
      moved_in_and_modified_file.update(parent_in_branch: folder,
                                        content_version: 'new-v')
      removed_file.update(is_deleted: true)

      # when I visit the project page
      visit "#{project.owner.to_param}/#{project.to_param}"
      # and click on Files
      click_on 'Files'
      # and click on Capture Changes
      click_on 'Capture Changes'
      # and unselect all changes
      uncheck "#{moved_in_and_modified_file.name} moved"
      uncheck "#{moved_in_and_modified_file.name} modified"
      uncheck "#{removed_file.name} deleted"
      uncheck "#{added_file.name} added"
      # and enter a revision title
      fill_in 'Title', with: 'Initial Capture'
      # and click on 'Capture'
      click_on 'Capture'

      # then the latest revision should have no diffs
      expect(master_branch.commits.last.file_diffs).to be_none
    end

    scenario 'User can unselect some changes' do
      # given there are files and they are committed in a project
      _files = [unchanged, folder, moved_in_and_modified_file, removed_file]
      create_revision
      # and I am signed in as its owner
      sign_in_as project.owner.account

      # when changes are made to files
      added_file
      moved_in_and_modified_file.update(parent_in_branch: folder,
                                        content_version: 'new-v')
      removed_file.update(is_deleted: true)

      # when I visit the project page
      visit "#{project.owner.to_param}/#{project.to_param}"
      # and click on Files
      click_on 'Files'
      # and click on Capture Changes
      click_on 'Capture Changes'
      # and unselect all changes
      uncheck "#{moved_in_and_modified_file.name} moved"
      uncheck "#{removed_file.name} deleted"
      # and enter a revision title
      fill_in 'Title', with: 'Initial Capture'
      # and click on 'Capture'
      click_on 'Capture'

      # then the latest revision should have two file changes
      expect(master_branch.commits.last.file_changes.count).to eq 2
      expect(master_branch.commits.last.file_changes).to be_one(&:modification?)
      expect(master_branch.commits.last.file_changes).to be_one(&:addition?)
    end
  end
end
