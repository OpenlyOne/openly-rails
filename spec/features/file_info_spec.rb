# frozen_string_literal: true

feature 'File Info' do
  let(:project) { create :project, :setup_complete, :skip_archive_setup }
  let!(:root) { create :vcs_staged_file, :root, branch: project.master_branch }
  before { sign_in_as project.owner.account }

  scenario 'User can see file info' do
    # given there is a file and it is committed
    file = create :vcs_staged_file, name: 'File1', parent: root
    create_revision

    # when I visit the project page
    visit "#{project.owner.to_param}/#{project.to_param}"
    # and click on Files
    click_on 'Files'
    # and click on the file info button
    find('.file-info').click

    # then I should be on the file's info page
    expect(page).to have_current_path(
      "/#{project.owner.to_param}/#{project.to_param}/" \
      "files/#{file.external_id}/info"
    )
    # and see one revision
    expect(page.find_all('.revision .metadata .title b').map(&:text))
      .to eq [project.master_branch.commits.last].map(&:title)
    # and see A file change entry for the file
    expect(page.find_all('.revision-diff').map(&:text)).to eq(
      ['File1 added to Home']
    )
  end

  scenario 'User can see file info for newly added files' do
    # given there is an uncommitted file
    file = create :vcs_staged_file, name: 'File1', parent: root

    # when I visit the project page
    visit "#{project.owner.to_param}/#{project.to_param}"
    # and click on Files
    click_on 'Files'
    # and click on the file info button
    find('.file-info').click

    # then I should be on the file's info page
    expect(page).to have_current_path(
      "/#{project.owner.to_param}/#{project.to_param}/" \
      "files/#{file.external_id}/info"
    )
    # and see no revisions
    expect(page).to have_text 'No previous versions'
  end

  scenario 'User can see file info of deleted files' do
    # given there is a file that has been deleted since the last revision
    file = create :vcs_staged_file, name: 'File1', parent: root
    create_revision
    file.update(is_deleted: true)
    create_revision

    # when I visit the project page
    visit "#{project.owner.to_param}/#{project.to_param}"
    # and click on Revisions
    click_on 'Revisions'
    # and click on the file info button
    within ".revision[id='#{project.master_branch.commits.last.id}']" do
      click_on 'More'
    end

    # then I should be on the file's info page
    expect(page).to have_current_path(
      "/#{project.owner.to_param}/#{project.to_param}/" \
      "files/#{file.external_id}/info"
    )
    # and see two revisions
    expect(page.find_all('.revision .metadata .title b').map(&:text))
      .to eq project.master_branch.commits.order(id: :desc).map(&:title)
    # and see A file change entry for the file
    expect(page.find_all('.revision-diff').map(&:text)).to eq(
      ['File1 deleted from Home', 'File1 added to Home']
    )
  end

  def create_revision
    r = project.master_branch.commits.create_draft_and_commit_files!(project.owner)
    r.update(is_published: true, title: 'revision')
  end
end
