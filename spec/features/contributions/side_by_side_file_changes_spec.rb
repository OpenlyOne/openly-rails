# frozen_string_literal: true

feature 'Contributions: Side-by-Side File Changes' do
  let(:project)       { create :project, :setup_complete, :skip_archive_setup }
  let(:master_branch) { project.master_branch }
  let!(:root) do
    create :vcs_file_in_branch, :root, branch: project.master_branch
  end
  let(:contribution) { create :contribution, :mock_setup, project: project }

  before { sign_in_as project.owner.account }

  scenario 'User can see uncaptured content changes side-by-side' do
    # given there is one file
    file = create :vcs_file_in_branch, name: 'File1', parent_in_branch: root

    # and it has content
    content_before = <<~TEXT
      SAME CONTENT1

      SAME CONTENT2

      TO BE REMOVED

      SAME CONTENT3

      TO BE REMOVED TOO

      SAME CONTENT4
    TEXT

    file.content.update!(plain_text: content_before)

    create_revision('origin')

    # and there is a contribution
    contribution

    # when I modify file
    content_after = <<~TEXT
      SAME CONTENT1

      AN ADDITION

      SAME CONTENT2

      ANOTHER ADDITION

      SAME CONTENT3

      SAME CONTENT4
    TEXT

    contribution.files.without_root.first.tap do |forked_file|
      forked_file.update!(content_version: 'new-version')
      forked_file.content.update!(plain_text: content_after)
    end

    when_i_visit_the_contribution_page_and_click_on_files
    find('.file-info').click

    # and click on the diff
    click_on 'View side-by-side'

    # then I should be on the file's side-by-side change page
    expect(page).to have_current_path(
      "/#{project.owner.to_param}/#{project.to_param}" \
      "/contributions/#{contribution.id}" \
      "/changes/#{file.hashed_file_id}"
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

  scenario 'User can see captured content changes side-by-side' do
    # given there is one file
    file = create :vcs_file_in_branch, name: 'File1', parent_in_branch: root

    # and it has content
    content_before = <<~TEXT
      SAME CONTENT1

      SAME CONTENT2

      TO BE REMOVED

      SAME CONTENT3

      TO BE REMOVED TOO

      SAME CONTENT4
    TEXT

    file.content.update!(plain_text: content_before)

    create_revision('origin')

    # when I modify file
    content_after = <<~TEXT
      SAME CONTENT1

      AN ADDITION

      SAME CONTENT2

      ANOTHER ADDITION

      SAME CONTENT3

      SAME CONTENT4
    TEXT

    file.update!(content_version: 'new-version')
    file.content.update!(plain_text: content_after)

    # and that is committed, too
    create_revision('second')

    # and there is a contribution
    contribution

    when_i_visit_the_contribution_page_and_click_on_files
    find('.file-info').click

    # and click on the diff
    click_on 'View side-by-side'

    # then I should be on the file's side-by-side change page
    expect(page).to have_current_path(
      "/#{project.owner.to_param}/#{project.to_param}/" \
      "revisions/#{VCS::Commit.last.to_param}/changes/#{file.hashed_file_id}"
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

def when_i_visit_the_contribution_page_and_click_on_files
  visit "#{project.owner.to_param}/#{project.to_param}"
  click_on 'Contributions'
  click_on contribution.title
  within '.page-subheading' do
    click_on 'Files'
  end
end
