# frozen_string_literal: true

feature 'File Info' do
  scenario 'User can see file info' do
    # given there is a project
    project = create :project
    # with a committed file
    root = create :file, :root, repository: project.repository
    file = create :file, name: 'File1', parent: root
    first_revision = create :git_revision, repository: project.repository

    # when I visit the project page
    visit "#{project.owner.to_param}/#{project.to_param}"
    # and click on Files
    click_on 'Files'
    # and click on the file info button
    find('.file .info').click

    # then I should be on the file's info page
    expect(page).to have_current_path(
      "/#{project.owner.to_param}/#{project.to_param}/files/#{file.id}/info"
    )
    # and see one revision
    expect(page.find_all('.revision .metadata .title b').map(&:text))
      .to eq [first_revision].map(&:title)
    # and see A file change entry for the file
    expect(page.find_all('.revision-diff').map(&:text)).to eq(
      ['File1 added to Home']
    )
  end

  scenario 'User can see file info for newly added files' do
    # given there is a project
    project = create :project
    # with a newly added file
    root = create :file, :root, repository: project.repository
    file = create :file, name: 'File1', parent: root

    # when I visit the project page
    visit "#{project.owner.to_param}/#{project.to_param}"
    # and click on Files
    click_on 'Files'
    # and click on the file info button
    find('.file .info').click

    # then I should be on the file's info page
    expect(page).to have_current_path(
      "/#{project.owner.to_param}/#{project.to_param}/files/#{file.id}/info"
    )
    # and see no revisions
    expect(page).to have_text 'No previous versions'
  end

  scenario 'User can see file info of deleted files' do
    # given there is a project
    project = create :project
    # with a committed file that has been deleted
    root = create :file, :root, repository: project.repository
    file = create :file, name: 'File1', parent: root
    first_revision = create :git_revision, repository: project.repository
    file.destroy
    second_revision = create :git_revision, repository: project.repository

    # when I visit the project page
    visit "#{project.owner.to_param}/#{project.to_param}"
    # and click on Revisions
    click_on 'Revisions'
    # and click on the file info button
    within ".revision[id='#{second_revision.id}']" do
      click_on 'More'
    end

    # then I should be on the file's info page
    expect(page).to have_current_path(
      "/#{project.owner.to_param}/#{project.to_param}/files/#{file.id}/info"
    )
    # and see two revisions
    expect(page.find_all('.revision .metadata .title b').map(&:text))
      .to eq [second_revision, first_revision].map(&:title)
    # and see A file change entry for the file
    expect(page.find_all('.revision-diff').map(&:text)).to eq(
      ['File1 deleted from Home', 'File1 added to Home']
    )
  end
end
