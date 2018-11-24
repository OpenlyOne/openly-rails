# frozen_string_literal: true

RSpec.describe 'contributions/index', type: :view do
  let(:project)       { build_stubbed :project }
  let(:contributions) { build_stubbed_list :contribution, 3 }

  before do
    assign(:project, project)
    assign(:contributions, contributions)
  end

  it 'renders the title of each contribution' do
    render
    contributions.each do |contribution|
      expect(rendered).to have_css(
        ".contribution[id='#{contribution.id}'] .title",
        text: contribution.title
      )
    end
  end

  it 'renders the description of each contribution' do
    render
    contributions.each do |contribution|
      expect(rendered).to have_css(
        ".contribution[id='#{contribution.id}'] .description",
        text: contribution.description
      )
    end
  end

  it 'renders the author of each contribution with link' do
    render
    contributions.map(&:creator).each do |creator|
      expect(rendered).to have_css '.contribution .profile', text: creator.name
      expect(rendered).to have_link creator.name, href: profile_path(creator)
    end
  end

  it 'renders a timestamp' do
    render
    contributions.each do |contribution|
      expect(rendered).to have_text(
        time_ago_in_words(contribution.created_at)
      )
    end
  end

  it 'renders a link to each contribution' do
    render
    contributions.each do |contribution|
      expect(rendered).to have_link(
        contribution.title,
        href: profile_project_contribution_path(project.owner, project,
                                                contribution)
      )
    end
  end

  it 'has a button to create a new contribution' do
    render
    expect(rendered).to have_link(
      'New Contribution',
      href: new_profile_project_contribution_path(project.owner, project)
    )
  end
end
