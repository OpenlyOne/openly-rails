# frozen_string_literal: true

feature 'Contributions: Review Changes' do
  let(:project)       { create :project, :setup_complete, :skip_archive_setup }
  let(:master_branch) { project.master_branch }
  let!(:root) do
    create :vcs_file_in_branch, :root, branch: project.master_branch
  end
  let(:contribution) { create :contribution, :mock_setup, project: project }

  let(:unchanged) do
    create_list :vcs_file_in_branch, 2,
                name: 'unchanged', parent_in_branch: root
  end
  let(:folder) { create :vcs_file_in_branch, :folder, parent_in_branch: root }
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
  let(:added_file) do
    create :vcs_file_in_branch, parent_in_branch: in_contribution(folder)
  end

  before { sign_in_as project.owner.account }

  scenario 'User can review changes' do
    # given there are files and they are committed in a project
    _files = [
      unchanged, folder, modified_file, moved_out_file, moved_in_file,
      moved_in_and_modified_file, removed_file, moved_folder, in_moved_folder
    ]
    create_revision('origin')

    # and I start a contribution
    contribution

    # when changes are made to files
    added_file
    in_contribution(modified_file).update(content_version: 'new-version')
    in_contribution(moved_out_file).update(parent: root.file)
    in_contribution(moved_in_file).update(parent: folder.file)
    in_contribution(moved_in_and_modified_file).update(parent: folder.file,
                                                       content_version: 'new-v')
    in_contribution(removed_file).update(is_deleted: true)
    in_contribution(moved_folder).update(parent: folder.file)

    # when I visit the project page
    visit "#{project.owner.to_param}/#{project.to_param}"
    # and click on Files
    click_on 'Contributions'
    # and click on the contribution
    click_on contribution.title
    # and click on review
    click_on 'Review'

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

  scenario 'Changes to review are relative to contribution origin' do
    # given there are files and they are committed in a project
    file_to_change_in_contribution_only =
      create :vcs_file_in_branch, name: 'contrib only', parent_in_branch: root
    file_to_change_in_both =
      create :vcs_file_in_branch, name: 'in both', parent_in_branch: root
    file_to_change_in_master_only =
      create :vcs_file_in_branch, name: 'master only', parent_in_branch: root
    folder = create :vcs_file_in_branch, :folder, parent_in_branch: root

    create_revision('origin')

    # and I start a contribution
    contribution

    # when changes are made on master
    file_to_change_in_both.update!(name: 'in both (new)')
    file_to_change_in_master_only.update!(name: 'master only (new)')
    # and committed
    create_revision('update')

    # when changes are made in the contribution
    in_contribution(file_to_change_in_contribution_only)
      .update!(name: 'contrib only (new)')
    in_contribution(file_to_change_in_both).update!(parent: folder.file)

    # when I visit the project page
    visit "#{project.owner.to_param}/#{project.to_param}"
    # and click on Files
    click_on 'Contributions'
    # and click on the contribution
    click_on contribution.title
    # and click on review
    click_on 'Review'

    # then I can see that it is suggested to add file
    expect(page).to have_css '.file.movement', text: 'in both'
    expect(page).to have_css '.file.rename', text: 'in both'
    expect(page).to have_css '.file.rename', text: 'contrib only (new)'

    # and not suggested to undo the change in master
    expect(page).not_to have_css '.file.rename', text: 'master only (new)'
  end
end

def create_revision(title)
  c = master_branch.commits.create_draft_and_commit_files!(project.owner)
  c.update!(is_published: true, title: title)
end

# Return the forked FileInBranch instance in the contribution
def in_contribution(file)
  contribution.files.find_by!(file_id: file.file_id)
end
