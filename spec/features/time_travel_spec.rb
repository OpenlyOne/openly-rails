# frozen_string_literal: true

feature 'Time Travel' do
  let(:project)   { create :project, :setup_complete, :skip_archive_setup }
  let(:root)      { create :file_resource, :folder }
  let(:files)     { create_list :file_resource, 5, :with_backup, parent: root }
  let(:revision) do
    project.revisions.create_draft_and_commit_files!(project.owner)
  end
  let(:publish_revision) do
    revision.update(is_published: true, title: 'origin revision')
  end

  before do
    project.root_folder = root
    files
  end

  before { sign_in_as project.owner.account }

  scenario 'User can view committed root-folder' do
    # given there is a published revision with files
    publish_revision

    # when I visit the revision page
    # TODO: Implement route splitter
    # visit "#{project.owner.to_param}/#{project.to_param}/" \
    #       "revisions/#{revision.id}"
    visit "/#{project.owner.to_param}/#{project.to_param}/" \
          "revisions/#{revision.id}/files"

    # then I should be on the revision's files page
    expect(page).to have_current_path(
      "/#{project.owner.to_param}/#{project.to_param}/" \
      "revisions/#{revision.id}/files"
    )
    # and see the revision title
    expect(page).to have_text(revision.title)
    # and see the files in the project root folder
    files.each do |file|
      expect(page).to have_link(
        file.name,
        href: file.current_snapshot.backup.file_resource.external_link
      )
    end
  end

  scenario 'User can see files in correct order' do
    # given I also have folders in my revision
    folders = create_list :file_resource, 5, :folder, parent: root
    # and my revision is published
    publish_revision

    # when I visit the revision page
    # TODO: Implement route splitter
    # visit "#{project.owner.to_param}/#{project.to_param}/" \
    #       "revisions/#{revision.id}"
    visit "/#{project.owner.to_param}/#{project.to_param}/" \
          "revisions/#{revision.id}/files"

    # then I should see files in the correct order
    file_order = FileResource.where(id: folders).order(:name).pluck(:name) +
                 FileResource.where(id: files).order(:name).pluck(:name)
    expect(page.all('.file').map(&:text)).to eq file_order
  end
end
