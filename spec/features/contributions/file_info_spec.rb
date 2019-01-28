# frozen_string_literal: true

feature 'Contributions: File Info' do
  let(:project)       { create :project, :setup_complete, :skip_archive_setup }
  let(:master_branch) { project.master_branch }
  let!(:root) do
    create :vcs_file_in_branch, :root, branch: project.master_branch
  end
  let(:contribution) { create :contribution, :mock_setup, project: project }

  before { sign_in_as project.owner.account }

  scenario 'User can see file info' do
    # given there is a file and it is committed
    file = create :vcs_file_in_branch, name: 'File1', parent_in_branch: root
    create_revision

    # and there is a contribution
    contribution

    when_i_visit_the_contribution_page_and_click_on_files
    find('.file-info').click

    # then I should be on the file's info page
    expect(page).to have_current_path(
      "/#{project.owner.to_param}/#{project.to_param}" \
      "/contributions/#{contribution.id}" \
      "/files/#{file.hashed_file_id}/info"
    )
    # and see one revision
    expect(page.find_all('.revision .metadata .title b').map(&:text))
      .to contain_exactly(project.master_branch.commits.last.title)
    # and see A file change entry for the file
    expect(page.find_all('.revision-diff').map(&:text)).to eq(
      ['File1 added to Home']
    )
  end

  scenario 'User can see file info for newly added files' do
    # given there is a contribution
    contribution
    # withan uncommitted file
    file = create :vcs_file_in_branch,
                  name: 'File1', parent_in_branch: contribution.branch.root

    when_i_visit_the_contribution_page_and_click_on_files
    find('.file-info').click

    # then I should be on the file's info page
    expect(page).to have_current_path(
      "/#{project.owner.to_param}/#{project.to_param}" \
      "/contributions/#{contribution.id}" \
      "/files/#{file.hashed_file_id}/info"
    )
    # and see no revisions
    expect(page).to have_text 'No previous versions'
  end
end

def create_revision
  r = master_branch.commits.create_draft_and_commit_files!(project.owner)
  r.update(is_published: true, title: 'revision')
end

def when_i_visit_the_contribution_page_and_click_on_files
  visit "#{project.owner.to_param}/#{project.to_param}"
  click_on 'Contributions'
  click_on contribution.title
  within '.page-subheading' do
    click_on 'Files'
  end
end
