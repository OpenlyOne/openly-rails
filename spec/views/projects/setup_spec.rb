# frozen_string_literal: true

RSpec.describe 'projects/setup', type: :view do
  let(:project) { create(:project) }

  before { assign(:project, project) }

  it 'renders a form with import_profile_project_path action' do
    render
    expect(rendered).to have_css(
      'form'\
      "[action='#{import_profile_project_path(project.owner, project)}']"\
      "[method='post']"
    )
  end

  it 'renders errors' do
    project.errors.add(:base, 'mock error')
    render
    expect(rendered).to have_css '.validation-errors', text: 'mock error'
  end

  it 'has an input field for link to Google Drive folder' do
    render
    expect(rendered).to have_css 'input#project_link_to_google_drive_folder'
  end

  it 'has a button to import the folder' do
    render
    expect(rendered)
      .to have_css "button[action='submit']", text: 'Import'
  end
end
