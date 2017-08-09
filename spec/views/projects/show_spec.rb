# frozen_string_literal: true

RSpec.describe 'projects/show', type: :view do
  let(:project) { create(:project) }

  before { assign(:project, project) }

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
end
