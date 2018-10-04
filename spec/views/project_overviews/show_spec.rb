# frozen_string_literal: true

RSpec.describe 'project_overviews/show', type: :view do
  let(:project)       { build_stubbed(:project) }
  let(:collaborators) { [] }

  before do
    assign(:project, project)
    assign(:collaborators, collaborators)
  end

  it 'renders the tags of the project' do
    render
    project.tags.each do |tag|
      expect(rendered).to have_css '.tag', text: view.tag_case(tag)
    end
  end

  it 'renders the description of the project' do
    render
    expect(rendered).to have_text project.description
  end

  it 'does not have a link to edit the project' do
    render
    expect(rendered).not_to have_css(
      "a[href='#{edit_profile_project_path(project.owner, project)}']"
    )
  end

  it 'shows the project owner with link to their profile' do
    render
    expect(rendered).to have_link(
      project.owner.name,
      href: profile_path(project.owner)
    )
  end

  context 'when project has collaborators' do
    let(:collaborators) { build_list :user, 2 }

    it 'shows the collaborators with link to their profile' do
      render
      collaborators.each do |collaborator|
        expect(rendered).to have_link(
          collaborator.name,
          href: profile_path(collaborator)
        )
      end
    end
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
