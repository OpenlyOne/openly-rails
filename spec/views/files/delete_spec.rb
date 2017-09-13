# frozen_string_literal: true

RSpec.describe 'files/delete', type: :view do
  let(:project) { create(:project) }
  let(:file)    { create(:vc_file, collection: project.files) }

  before do
    assign(:project, project)
    assign(:file, file)
    assign(:file_action, :rename)
  end

  it 'renders a form with delete_profile_project_file_path action' do
    delete_path = delete_profile_project_file_path project.owner, project, file
    render
    expect(rendered).to have_css(
      'form'\
      "[action='#{delete_path}']"\
      "[method='post']"
    )
  end

  it 'uses method :delete' do
    render
    expect(rendered)
      .to have_css("input[name='_method'][value='delete']", visible: false)
  end

  it 'renders errors' do
    file.errors.add(:base, 'mock error')
    render
    expect(rendered).to have_css '.validation-errors', text: 'mock error'
  end

  it 'has an input field for revision summary' do
    render
    expect(rendered).to have_css 'input#version_control_file_revision_summary'
  end

  it 'has a button to delete the file' do
    render
    expect(rendered).to have_css "button[action='submit']", text: 'Delete'
  end
end
