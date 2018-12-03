# frozen_string_literal: true

RSpec.describe 'revisions/index', type: :view do
  let(:project)       { build_stubbed :project, :with_repository }
  let(:repository)    { project.repository }
  let(:master_branch) { build_stubbed :vcs_branch, repository: repository }
  let(:revisions)     { build_stubbed_list :vcs_commit, 3 }
  let(:versions)      { build_stubbed_list(:vcs_version, 3) }
  let(:diffs) do
    versions.map do |version|
      VCS::FileDiff.new(current_version: version, first_three_ancestors: [])
    end
  end

  before do
    assign(:project, project)
    assign(:revisions, revisions)
    controller.request.path_parameters[:profile_handle] = project.owner.to_param
    controller.request.path_parameters[:project_slug] = project.to_param

    root = instance_double VCS::FileInBranch
    allow(master_branch).to receive(:root).and_return root
    allow(revisions.first).to receive(:file_diffs).and_return diffs
  end

  context 'rendering PDF documents' do
    let(:versions) { build_stubbed_list(:vcs_version, 3, :pdf) }

    it 'does not raise an error' do
      render
      versions.each do |version|
        expect(rendered).to have_text version.name
      end
    end
  end
end
