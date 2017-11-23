# frozen_string_literal: true

RSpec.describe 'projects/show', type: :view do
  let(:project) { create(:project) }

  before do
    assign(:project, project)
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

  context 'when current user can edit project' do
    before { assign(:user_can_edit_project, true) }

    it 'does have a link to edit the project' do
      render
      expect(rendered).to have_css(
        "a[href='#{edit_profile_project_path(project.owner, project)}']"
      )
    end
  end

  context 'when a root folder exists' do
    before { create :file_items_folder, project: project, parent: nil }

    it 'renders a link to the project files' do
      render
      expect(rendered).to have_link(
        'Files',
        href: profile_project_root_folder_path(project.owner, project.slug)
      )
    end

    it 'renders a link to open that folder in Google Drive' do
      render
      expect(rendered).to have_link(
        'Open in Drive',
        href: project.root_folder.external_link
      )
    end
  end
end
