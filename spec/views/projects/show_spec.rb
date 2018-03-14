# frozen_string_literal: true

RSpec.describe 'projects/show', type: :view do
  let(:project)       { build_stubbed(:project) }
  let(:collaborators) { [] }

  before do
    assign(:project, project)
    assign(:collaborators, collaborators)
  end

  it 'renders the title of the project' do
    render
    expect(rendered).to have_text project.title
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

  context 'when setup has not started' do
    before { allow(project).to receive(:setup_not_started?).and_return true }

    it 'renders a link to start the project setup' do
      render
      expect(rendered).to have_link(
        'Setup',
        href: new_profile_project_setup_path(project.owner, project.slug)
      )
    end
  end

  context 'when setup is in progress' do
    before { allow(project).to receive(:setup_not_started?).and_return false }
    before { allow(project).to receive(:setup_in_progress?).and_return true }

    it 'renders a link to the setup status' do
      render
      expect(rendered).to have_link(
        'Setup',
        href: profile_project_setup_path(project.owner, project.slug)
      )
    end
  end

  context 'when setup is complete' do
    let(:root) { build_stubbed :file_resource }
    before { allow(project).to receive(:root_folder).and_return root }

    before { allow(project).to receive(:setup_not_started?).and_return false }
    before { allow(project).to receive(:setup_in_progress?).and_return false }
    before { allow(project).to receive(:setup_completed?).and_return true }

    it 'renders a link to the project files' do
      render
      expect(rendered).to have_link(
        'Files',
        href: profile_project_root_folder_path(project.owner, project.slug)
      )
    end

    it 'renders a link to the project revisions' do
      render
      expect(rendered).to have_link(
        'Revisions',
        href: profile_project_revisions_path(project.owner, project.slug)
      )
    end

    it 'renders a link to open that folder in Google Drive' do
      render
      expect(rendered).to have_link(
        'Open in Drive', href: root.external_link
      )
    end
  end
end
