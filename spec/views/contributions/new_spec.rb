# frozen_string_literal: true

RSpec.describe 'contributions/new', type: :view do
  let(:project)       { build_stubbed :project }
  let(:contribution)  { build_stubbed :contribution, project: project }

  before do
    assign(:project, project)
    assign(:contribution, contribution)
  end

  it 'renders a form with profile_project_contribution_path action' do
    render
    action_path = profile_project_contributions_path(project.owner, project)
    expect(rendered).to have_css(
      "form[action='#{action_path}'][method='post']"
    )
  end

  it 'renders errors' do
    contribution.errors.add(:base, 'mock error')
    render
    expect(rendered).to have_css '.validation-errors', text: 'mock error'
  end

  it 'has a text field for contribution title' do
    render
    expect(rendered).to have_css 'input#contribution_title'
  end

  it 'has a text area for contribution description' do
    render
    expect(rendered).to have_css 'textarea#contribution_description'
  end

  it 'has a button to create the contribution' do
    render
    expect(rendered)
      .to have_css "button[action='submit']", text: 'Create Contribution'
  end
end
