# frozen_string_literal: true

RSpec.describe 'files/new', type: :view do
  let(:project) { create(:project) }
  let(:file)    { create(:vc_file, collection: project.files) }

  before do
    assign(:project, project)
    assign(:file, file)
    assign(:file_action, :rename)
  end

  it 'renders a form with profile_project_files_path action' do
    create_path = profile_project_files_path project.owner, project, file
    render
    expect(rendered).to have_css(
      'form'\
      "[action='#{create_path}']"\
      "[method='post']"
    )
  end

  it 'renders errors' do
    file.errors.add(:base, 'mock error')
    render
    expect(rendered).to have_css '.validation-errors', text: 'mock error'
  end

  it 'has an input field for name' do
    render
    expect(rendered).to have_css 'input#version_control_file_name'
  end

  it 'has an input field for content' do
    render
    expect(rendered).to have_css 'textarea#version_control_file_content'
  end

  it 'has an input field for revision summary' do
    render
    expect(rendered).to have_css 'input#version_control_file_revision_summary'
  end

  it 'has a button to create the file' do
    render
    expect(rendered).to have_css "button[action='submit']", text: 'Create'
  end
end
