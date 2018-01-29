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

  it 'renders the about text of the profile' do
    render
    expect(rendered).to have_text profile.about
  end

  it 'lists projects with title & tags & description' do
    render
    projects.each do |project|
      expect(rendered).to have_text project.title
      expect(rendered).to have_text view.tag_case(project.tags.first)
      expect(rendered).to have_text truncate(project.description, length: 200)
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

  context 'when current user can edit profile' do
    before { assign(:user_can_edit_profile, true) }

    it 'does have a link to edit the profile' do
      render
      expect(rendered).to have_css(
        "a[href='#{edit_profile_path(profile)}']"
      )
    end
  end
end
