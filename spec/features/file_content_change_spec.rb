# frozen_string_literal: true

feature 'File Content Change' do
  let(:project)       { create :project, :setup_complete, :skip_archive_setup }
  let(:master_branch) { project.master_branch }
  let!(:root) { create :vcs_file_in_branch, :root, branch: master_branch }

  before { sign_in_as project.owner.account }

  scenario 'User can see content changes on revisions page' do
    # given there are two committed files
    file1 = create :vcs_file_in_branch, name: 'File1', parent_in_branch: root
    file2 = create :vcs_file_in_branch, name: 'File2', parent_in_branch: root

    # and both have content
    file1.content.update!(plain_text: 'file1 content')
    file2.content.update!(plain_text: 'file2 content')

    create_revision('origin')

    # when I modify file1, delete file2, and add file3
    file1.update!(content_version: 'new-version')
    file1.content.update!(plain_text: 'file1 new content')
    file2.tap(&:mark_as_removed).tap(&:save)
    file3 = create :vcs_file_in_branch, name: 'File3', parent_in_branch: root
    file3.content.update!(plain_text: 'file3 content')

    create_revision('second')

    # when I visit the project page
    visit "#{project.owner.to_param}/#{project.to_param}"

    # and click on Revisions
    click_on 'Revisions'

    # then I should see one file change
    expect(page).to have_text(
      'file1 new content'
    )

    # and not see changes for file2 or file3
    expect(page).not_to have_text('file2 content')
    expect(page).not_to have_text('file3 content')
  end

  scenario 'User can see content changes on capture changes page' do
    # given there are two committed files
    file1 = create :vcs_file_in_branch, name: 'File1', parent_in_branch: root
    file2 = create :vcs_file_in_branch, name: 'File2', parent_in_branch: root

    # and both have content
    file1.content.update!(plain_text: 'file1 content')
    file2.content.update!(plain_text: 'file2 content')

    create_revision('origin')

    # when I modify file1, delete file2, and add file3
    file1.update!(content_version: 'new-version')
    file1.content.update!(plain_text: 'file1 new content')
    file2.tap(&:mark_as_removed).tap(&:save)
    file3 = create :vcs_file_in_branch, name: 'File3', parent_in_branch: root
    file3.content.update!(plain_text: 'file3 content')

    # when I visit the project page
    visit "#{project.owner.to_param}/#{project.to_param}"

    # and click on Capture Changes
    click_on 'Capture Changes'

    # then I should see one file change
    expect(page).to have_text(
      'file1 new content'
    )

    # and not see changes for file2 or file3
    expect(page).not_to have_text('file2 content')
    expect(page).not_to have_text('file3 content')
  end

  scenario 'User can see content changes on file infos page' do
    # given there are two committed files
    file1 = create :vcs_file_in_branch, name: 'File1', parent_in_branch: root

    # and both have content
    file1.content.update!(plain_text: 'file1 content')

    create_revision('origin')

    # when I modify file1, delete file2, and add file3
    file1.update!(content_version: 'new-version')
    file1.content.update!(plain_text: 'file1 new content')

    # when I visit the project page
    visit "#{project.owner.to_param}/#{project.to_param}"

    # and click on file info
    find('.file-info').click

    # then I should see the file change
    expect(page).to have_text(
      'file1 new content'
    )
  end

  scenario 'User can see content changes side-by-side' do
    # given there are two committed files
    file = create :vcs_file_in_branch, name: 'File1', parent_in_branch: root

    # and both have content
    content_before = <<~TEXT
      SAME CONTENT1

      SAME CONTENT2

      TO BE REMOVED

      SAME CONTENT3

      TO BE REMOVED TOO

      SAME CONTENT4
    TEXT

    content_after = <<~TEXT
      SAME CONTENT1

      AN ADDITION

      SAME CONTENT2

      ANOTHER ADDITION

      SAME CONTENT3

      SAME CONTENT4
    TEXT

    file.content.update!(plain_text: content_before)

    create_revision('origin')

    # when I modify file
    file.update!(content_version: 'new-version')
    file.content.update!(plain_text: content_after)

    # when I visit the project page
    visit "#{project.owner.to_param}/#{project.to_param}"

    # and click on file info
    find('.file-info').click

    # and click on the diff
    click_on 'View side-by-side'

    # then I should be on the file's side-by-side change page
    expect(page).to have_current_path(
      "/#{project.owner.to_param}/#{project.to_param}/" \
      "changes/#{file.hashed_file_id}"
    )

    # then I should see the file change side by side
    expect(
      Nokogiri::HTML(
        all('.old').map do |old_content|
          old_content.native.inner_html.gsub(/<br\\?>/, "\n")
        end.join
      ).text
    ).to eq content_before

    expect(
      Nokogiri::HTML(
        all('.new').map do |new_content|
          new_content.native.inner_html.gsub(/<br\\?>/, "\n")
        end.join
      ).text
    ).to eq content_after
  end

  def create_revision(title)
    c = master_branch.commits.create_draft_and_commit_files!(project.owner)
    c.update!(is_published: true, title: title)
  end
end
