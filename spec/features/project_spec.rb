# frozen_string_literal: true

feature 'Project' do
  scenario 'User can view project' do
    # given there is a project
    project = create(:project)

    # when I visit the project
    visit "/#{project.owner.handle.identifier}/#{project.slug}"

    # then I should see the project's title
    expect(page).to have_text project.title
  end
end
