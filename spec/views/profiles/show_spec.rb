# frozen_string_literal: true

RSpec.describe 'profiles/show', type: :view do
  let(:profile) { build(:user, :with_social_links) }
  let(:projects) do
    build_stubbed_list(:project, 3, :with_repository, owner: profile)
  end

  before do
    assign(:profile, profile)
    assign(:projects, projects)
  end

  it 'renders the name of the profile' do
    render
    expect(rendered).to have_text profile.name
  end

  it 'renders the social links of the profile' do
    render
    expect(rendered).to have_link href: profile.link_to_website
    expect(rendered).to have_link href: profile.link_to_facebook
    expect(rendered).to have_link href: profile.link_to_twitter
  end

  it 'renders the about text of the profile' do
    render
    expect(rendered).to have_text profile.about
  end

  it 'renders the location of the profile' do
    render
    expect(rendered).to have_text profile.location
  end

  it 'lists projects with title, description, and captured at' do
    render
    projects.each do |project|
      expect(rendered).to have_text project.title
      expect(rendered).to have_text truncate(project.description, length: 200)
      expect(rendered)
        .to have_text "Updated #{time_ago_in_words(project.captured_at)} ago"
    end
  end

  it 'lists projects without an uncaptured changes indicator' do
    render
    expect(rendered).not_to have_css '.uncaptured-changes-indicator'
  end

  context 'when user can collaborate' do
    before do
      allow(projects.first).to receive(:can_collaborate?).and_return true
      render
    end

    it { expect(rendered).not_to have_css '.uncaptured-changes-indicator' }
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

  context 'when project has uncaptured changes' do
    before do
      allow(projects.first).to receive(:uncaptured_changes_count).and_return 7
    end

    context 'when user can collaborate' do
      before do
        allow(projects.first).to receive(:can_collaborate?).and_return true
        render
      end

      it { expect(rendered).to have_css '.uncaptured-changes-indicator' }
    end

    context 'when user cannot collaborate' do
      before { render }

      it { expect(rendered).not_to have_css '.uncaptured-changes-indicator' }
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
