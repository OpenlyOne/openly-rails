# frozen_string_literal: true

RSpec.describe 'project_setups/show', type: :view do
  let(:setup)   { build_stubbed(:project_setup) }
  let(:project) { setup.project }

  before { assign(:project, project) }
  before { assign(:setup, setup) }

  before do
    allow(project).to receive(:staged_non_root_files).and_return %w[1 2 3]
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
