# frozen_string_literal: true

RSpec.describe 'projects/show', type: :view do
  let(:project) { create(:project) }
  let(:file)    { project.files.find 'Overview' }

  before do
    assign(:project, project)
    assign(:overview, file)
  end

  it 'renders the title of the project' do
    render
    expect(rendered).to have_text project.title
  end

  it 'renders a link to the project home page' do
    render
    expect(rendered).to have_link(
      'Overview',
      href: profile_project_path(project.owner, project.slug)
    )
  end

  it 'does not have a link to edit the project' do
    render
    expect(rendered).not_to have_css(
      "a[href='#{edit_profile_project_path(project.owner, project)}']"
    )
  end

  it 'renders the contents of the Overview file' do
    render
    expect(rendered).to have_selector 'h3', text: 'Overview'
    expect(rendered).to have_text file.content
  end

  context 'when current user can edit project' do
    before { assign(:user_can_edit_project, true) }

    it 'does have a link to edit the project' do
      render
      expect(rendered).to have_css(
        "a[href='#{edit_profile_project_path(project.owner, project)}']"
      )
    end
  end
end
