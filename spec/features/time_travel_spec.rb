# frozen_string_literal: true

feature 'Time Travel' do
  let(:project) { create :project, :setup_complete, :skip_archive_setup }
  let(:root) { create :vcs_staged_file, :root, branch: project.master_branch }
  let!(:files) { create_list :vcs_staged_file, 5, :with_backup, parent: root }
  let(:commit) do
    project.master_branch.commits.create_draft_and_commit_files!(project.owner)
  end
  let(:publish_commit) do
    commit.update(is_published: true, title: 'origin revision')
  end

  before { sign_in_as project.owner.account }

  scenario 'User can view committed root-folder' do
    # given there is a published revision with files
    publish_commit

    # when I visit the commits page
    visit profile_project_revisions_path(project.owner, project)

    # and click on the revision title
    click_on commit.title

    # then I should be on the revision's files page
    expect(page).to have_current_path(
      "/#{project.owner.to_param}/#{project.to_param}/" \
      "revisions/#{commit.id}/files"
    )
    # and see the revision title
    expect(page).to have_text(commit.title)
    # and see the files in the project root folder
    files.each do |file|
      expect(page).to have_link(
        file.name,
        href: file.current_snapshot.backup.external_link
      )
    end
  end

  scenario 'User can see files in correct order' do
    # given I also have folders in my revision
    folders = create_list :vcs_staged_file, 5, :folder, parent: root
    # and my commit is published
    publish_commit

    # when I visit the commits page
    visit profile_project_revisions_path(project.owner, project)

    # and click on the commit title
    click_on commit.title

    # then I should see files in the correct order
    file_order = VCS::StagedFile.where(id: folders).order(:name).pluck(:name) +
                 VCS::StagedFile.where(id: files).order(:name).pluck(:name)
    expect(page.all('.file').map(&:text)).to eq file_order
  end

  scenario 'User can view committed sub-folder' do
    # given a variety of sub-folders and files
    folder    = create :vcs_staged_file, :folder, name: 'Fol', parent: root
    docs      = create :vcs_staged_file, :folder, name: 'Docs', parent: folder
    code      = create :vcs_staged_file, :folder, name: 'Code', parent: docs
    subfiles  = create_list :vcs_staged_file, 5, parent: code

    # and a published commit
    publish_commit

    # when I visit the commits page
    visit profile_project_revisions_path(project.owner, project)

    # and click on the commit title
    click_on commit.title

    # and click on the folder folder
    click_on folder.name
    # and click on the docs folder
    click_on docs.name
    # and click on the code folder
    click_on code.name

    # then I should be on the project's subfolder page
    expect(page).to have_current_path(
      "/#{project.owner.to_param}/#{project.to_param}/" \
      "revisions/#{commit.id}/folders/#{code.remote_file_id}"
    )
    # and see the files in the project subfolder
    subfiles.each do |file|
      expect(page).to have_text file.name
    end
    # and see the ancestry path
    expect(page.find('.breadcrumbs').text).to eq 'Fol Docs Code'
  end
end
