# frozen_string_literal: true

feature 'File' do
  scenario 'User can view file' do
    # given there is a project
    project = create(:project)
    # with a file
    file = project.files.find 'Overview'

    # when I visit the file
    visit "/#{project.owner.to_param}/#{project.to_param}/files/#{file.name}"

    # then I see the file title
    expect(page).to have_text file.name
    # and contents
    expect(page).to have_text file.content
  end
end
