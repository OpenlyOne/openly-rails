# frozen_string_literal: true

feature 'Folder' do
  scenario 'User can view root-folder' do
    # given there is a project
    project = create :project
    # with some files and folders
    root = create :file, :root, repository: project.repository
    files = create_list :file, 5, parent: root

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
    # given there is a project
    project = create :project
    # with some files and folders
    root = create :file, :root, repository: project.repository
    create_list :file, 5, parent: root
    subfolder = create :file, :folder, parent: root
    subfiles = create_list :file, 5, parent: subfolder

    # when I visit the project page
    visit "#{project.owner.to_param}/#{project.to_param}"
    # and click on Files
    click_on 'Files'
    # and click on the subfolder
    click_on subfolder.name

    # then I should be on the project's subfolder page
    expect(page).to have_current_path(
      "/#{project.owner.to_param}/#{project.to_param}/folders/#{subfolder.id}"
    )
    # and see the files in the project subfolder
    subfiles.each do |file|
      expect(page).to have_text file.name
    end
  end

  scenario 'User can see files in correct order' do
    # given there is a project
    project = create :project
    # with some files and folders
    root        = create :file, :root, repository: project.repository
    directories = create_list :file, 5, :folder, parent: root
    files       = create_list :file, 5, parent: root

    # when I visit the project page
    visit "#{project.owner.to_param}/#{project.to_param}"
    # and click on Files
    click_on 'Files'

    # then I should see files in the correct order
    file_order = directories.map(&:name).sort + files.map(&:name).sort
    expect(page.all('.file').map(&:text)).to eq file_order
  end

  scenario 'User can see diffs in folder' do
    # given there is a project
    project = create :project
    # with some files and folders
    root = create :file, :root, repository: project.repository
    folder = create :file, :folder, parent: root
    modified_file = create :file, parent: folder
    moved_out_file = create :file, parent: folder
    moved_in_file = create :file, parent: root
    removed_file = create :file, parent: folder
    unchanged_file = create :file, parent: folder
    # and files are committed
    create :revision, repository: project.repository

    # when changes are made to files
    added_file = create :file, parent: folder
    update_file(modified_file, modified_time: Time.zone.now)
    update_file(moved_out_file, parent_id: root.id)
    update_file(moved_in_file, parent_id: folder.id)
    update_file(removed_file, parent_id: nil)

    # when I visit the project page
    visit "#{project.owner.to_param}/#{project.to_param}"
    # and click on Files
    click_on 'Files'
    # and click on the folder
    click_on folder.name

    # then I should see a diff for each file
    expect(page).to have_css '.file.added',     text: added_file.name
    expect(page).to have_css '.file.modified',  text: modified_file.name
    expect(page).to have_css '.file.moved',     text: moved_in_file.name
    expect(page).to have_css '.file.deleted',   text: removed_file.name
    expect(page).to have_css '.file.unchanged', text: unchanged_file.name

    # and not see the file that was moved out of the directory
    expect(page).not_to have_text moved_out_file
  end

  context 'User can see correct ancestry path for folders' do
    let!(:project)  { create :project }
    let!(:repo)     { project.repository }
    let!(:root)     { create :file, :root,   name: 'Root', repository: repo }
    let!(:folder)   { create :file, :folder, name: 'Folder',    parent: root }
    let!(:docs)     { create :file, :folder, name: 'Documents', parent: folder }
    let!(:code)     { create :file, :folder, name: 'Code',      parent: docs }
    before do
      # and folders are committed
      create :revision, repository: project.repository
    end
    let(:action) do
      # when I visit the code folder
      visit "#{project.owner.to_param}/#{project.to_param}/folders/#{code.id}"
    end

    context 'when code folder exists' do
      before  { action }

      it 'then ancestry path is root > folder > documents > code' do
        expect(page.find('.breadcrumbs').text).to eq 'Folder Documents Code'
      end
    end

    context 'when code folder is removed' do
      before  { update_file(code, parent_id: nil) }
      before  { action }

      it 'then ancestry path is root > folder > documents > code' do
        expect(page.find('.breadcrumbs').text).to eq 'Folder Documents Code'
      end
    end

    context 'when code folder is removed and documents is moved into root' do
      before  { update_file(code, parent_id: nil) }
      before  { update_file(docs, name: 'The Docs', parent_id: root.id) }
      before  { action }

      it 'then ancestry path is root > documents > code' do
        expect(page.find('.breadcrumbs').text).to eq 'The Docs Code'
      end
    end
  end

  # update the file with the given parameters
  def update_file(file, params)
    params.reverse_merge!(
      name: file.name,
      parent_id: file.parent_id,
      mime_type: file.mime_type,
      version: file.version + 1,
      modified_time: file.modified_time
    )
    file.update(params)
  end
end
