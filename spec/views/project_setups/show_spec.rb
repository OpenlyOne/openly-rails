# frozen_string_literal: true

RSpec.describe 'project_setups/show', type: :view do
  let(:project)       { build_stubbed :project, :with_repository }
  let(:repository)    { project.repository }
  let(:master_branch) { build_stubbed :vcs_branch, repository: repository }
  let(:setup)         { build_stubbed(:project_setup, project: project) }

  before { assign(:project, project) }
  before { assign(:master_branch, master_branch) }
  before { assign(:setup, setup) }

  before do
    allow(master_branch).to receive(:files).and_return %w[1 2 3]
  end

  it 'displays the number of files already imported' do
    render
    expect(rendered).to have_text '3 files imported so far.'
  end

  it 'has a button to refresh the page' do
    render
    link = profile_project_setup_path(project.owner, project)
    expect(rendered).to have_link(text: 'Refresh', href: link)
  end
end
