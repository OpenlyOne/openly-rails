# frozen_string_literal: true

feature 'Folder' do
  let(:project) do
    create :project, :setup_complete, :skip_archive_setup, :with_repository
  end
  let(:branch)  { project.master_branch }
  let(:root)    { create :vcs_staged_file, :root, branch: branch }
  let!(:files) do
    create_list :vcs_staged_file, 5, parent: root
  end
  let(:create_revision) do
    c = branch.commits.create_draft_and_commit_files!(project.owner)
    c.update(is_published: true, title: 'origin revision')
  end

  before { sign_in_as project.owner.account }

  scenario 'User can view root-folder' do
    # when I visit the project page
    visit "#{project.owner.to_param}/#{project.to_param}"
    # and click on Files
    click_on 'Files'

    # then I should be on the project's files page
    expect(page).to have_current_path(
      "/#{project.owner.to_param}/#{project.to_param}/files"
    )
    # and see the files in the project root folder
    files.each do |file|
      expect(page).to have_text file.name
    end
  end

  scenario 'User can view sub-folder' do
    # given there is a subfolder
    subfolder =
      create :vcs_staged_file, :folder, name: 'A Unique Subfolder', parent: root
    subfiles = create_list :vcs_staged_file, 5, parent: subfolder

    # when I visit the project page
    visit "#{project.owner.to_param}/#{project.to_param}"
    # and click on Files
    click_on 'Files'
    # and click on the subfolder
    click_on subfolder.name

    # then I should be on the project's subfolder page
    expect(page).to have_current_path(
      "/#{project.owner.to_param}/#{project.to_param}/" \
      "folders/#{subfolder.external_id}"
    )
    # and see the files in the project subfolder
    subfiles.each do |file|
      expect(page).to have_text file.name
    end
  end

  scenario 'User can see files in correct order' do
    folders = create_list :vcs_staged_file, 5, :folder, parent: root

    # when I visit the project page
    visit "#{project.owner.to_param}/#{project.to_param}"
    # and click on Files
    click_on 'Files'

    # then I should see files in the correct order
    file_order = VCS::StagedFile.where(id: folders).order(:name).pluck(:name) +
                 VCS::StagedFile.where(id: files).order(:name).pluck(:name)
    expect(page.all('.file').map(&:text)).to eq file_order
  end

  scenario 'User can see diffs in folder' do
    folder                      = create :vcs_staged_file, :folder, parent: root
    modified_file               = create :vcs_staged_file, parent: folder
    moved_out_file              = create :vcs_staged_file, parent: folder
    moved_in_file               = create :vcs_staged_file, parent: root
    moved_in_and_modified_file  = create :vcs_staged_file, parent: root
    removed_file                = create :vcs_staged_file, parent: folder
    unchanged_file              = create :vcs_staged_file, parent: folder
    # and files are committed
    create_revision

    # when changes are made to files
    added_file = create :vcs_staged_file, parent: folder
    modified_file.update(content_version: 'new-version')
    moved_out_file.update(file_record_parent_id: root.file_record_id)
    moved_in_file.update(file_record_parent_id: folder.file_record_id)
    moved_in_and_modified_file.update(file_record_parent_id: folder.file_record_id,
                                      content_version: 'new-version')
    removed_file.update(is_deleted: true)

    # when I visit the project page
    visit "#{project.owner.to_param}/#{project.to_param}"
    # and click on Files
    click_on 'Files'
    # and click on the folder
    click_on folder.name

    # then I should see a diff for each file
    expect(page).to have_css '.file.addition',      text: added_file.name
    expect(page).to have_css '.file.modification',  text: modified_file.name
    expect(page).to have_css '.file.movement',      text: moved_in_file.name
    expect(page).to have_css '.file.movement.modification',
                             text: moved_in_and_modified_file.name
    expect(page).to have_css '.file.deletion',      text: removed_file.name
    expect(page).to have_css '.file.no-change',     text: unchanged_file.name

    # and not see the file that was moved out of the directory
    expect(page).not_to have_text moved_out_file
  end

  context 'User can see correct ancestry path for folders' do
    let(:folder) { create :vcs_staged_file, :folder, name: 'Fol', parent: root }
    let(:docs) { create :vcs_staged_file, :folder, name: 'Docs', parent: folder }
    let(:code) { create :vcs_staged_file, :folder, name: 'Code', parent: docs }
    let(:init_folders) { [folder, docs, code] }
    before do
      init_folders
      create_revision
    end
    let(:action) do
      # when I visit the code folder
      visit "#{project.owner.to_param}/#{project.to_param}/" \
            "folders/#{code.external_id}"
    end

    context 'when code folder exists' do
      before  { action }

      it 'then ancestry path is root > folder > documents > code' do
        expect(page.find('.breadcrumbs').text).to eq 'Fol Docs Code'
      end
    end

    context 'when code folder is removed' do
      before  { code.update(parent: nil) }
      before  { action }

      it 'then ancestry path is root > folder > documents > code' do
        expect(page.find('.breadcrumbs').text).to eq 'Fol Docs Code'
      end
    end

    context 'when code folder is removed and documents is moved into root' do
      before  { code.update(parent: nil) }
      before  { docs.update(name: 'The Docs', parent: root) }
      before  { action }

      it 'then ancestry path is root > documents > code' do
        expect(page.find('.breadcrumbs').text).to eq 'The Docs Code'
      end
    end
  end
end
