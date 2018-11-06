# frozen_string_literal: true

RSpec.describe 'projects/_head', type: :view do
  let(:project) { build_stubbed(:project) }

  before do
    without_partial_double_verification do
      allow(view).to receive(:project) { project }
    end
  end

  it 'renders the title of the project' do
    render
    expect(rendered).to have_text project.title
  end

  it 'renders a link to the project home page' do
    render
    expect(rendered).to have_link(
      'Overview',
      href: profile_project_overview_path(project.owner, project.slug)
    )
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
    let(:root) { build_stubbed :vcs_staged_file, :root }

    before do
      branch = instance_double VCS::Branch
      allow(project).to receive(:master_branch).and_return branch
      allow(branch).to receive(:root).and_return root
      allow(project).to receive(:setup_not_started?).and_return false
      allow(project).to receive(:setup_in_progress?).and_return false
      allow(project).to receive(:setup_completed?).and_return true
    end

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
