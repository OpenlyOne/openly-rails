# frozen_string_literal: true

RSpec.describe 'profiles/show', type: :view do
  let(:profile) { build(:user) }
  let(:projects) { build_stubbed_list(:project, 3, owner: profile) }

  before do
    assign(:profile, profile)
    assign(:projects, projects)
  end

  it 'renders the name of the profile' do
    render
    expect(rendered).to have_text profile.name
  end

  it 'lists projects' do
    render
    projects.each do |project|
      expect(rendered).to have_text project.title
    end
  end

  it 'links to projects' do
    render
    projects.each do |project|
      expect(rendered).to have_link(
        project.title,
        href: profile_project_path(project.owner, project)
      )
    end
  end
end
