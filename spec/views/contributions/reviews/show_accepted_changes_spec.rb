# frozen_string_literal: true

require 'views/shared_examples/showing_content_changes.rb'

RSpec.describe 'contributions/reviews/show_accepted_changes', type: :view do
  let(:project)       { contribution.project }
  let(:repository)    { project.repository }
  let(:master_branch) { build_stubbed :vcs_branch, repository: repository }
  let(:revision)      { contribution.accepted_revision }
  let(:contribution)  { build_stubbed :contribution, :accepted }
  let(:file_diffs)    { [] }

  before { allow(revision).to receive(:file_diffs).and_return(file_diffs) }

  before do
    assign(:project, project)
    assign(:master_branch, master_branch)
    assign(:contribution, contribution)
    assign(:revision, revision)
    controller.request.path_parameters[:profile_handle] = project.owner.to_param
    controller.request.path_parameters[:project_slug] = project.to_param
  end

  it 'lets the user know that there are no changes to review' do
    render
    expect(rendered).to have_text 'No files changed.'
  end

  context 'when file diffs exist' do
    let(:file_diffs) do
      versions.map do |version|
        VCS::FileDiff.new(new_version: version, first_three_ancestors: [])
      end
    end
    let(:versions) do
      build_stubbed_list(:vcs_version, 3, :with_backup)
    end

    before do
      root = instance_double VCS::FileInBranch
      allow(master_branch).to receive(:root).and_return root
      allow(root).to receive(:provider).and_return Providers::GoogleDrive
      file_diffs.first.changes.each(&:unselect!)
    end

    it 'it lists files as added' do
      render
      file_diffs.each do |diff|
        expect(rendered)
          .to have_css('.file.addition', text: "#{diff.name} added")
      end
    end

    it 'renders a link to each file backup' do
      render
      file_diffs.each do |diff|
        link = diff.current_version.backup.link_to_remote
        expect(rendered).to have_link(text: diff.name, href: link)
      end
    end

    it_should_behave_like 'showing content changes' do
      let(:diff) { revision.file_changes.first }
      let(:link_to_side_by_side) do
        profile_project_revision_file_change_path(
          project.owner, project, revision, diff.hashed_file_id
        )
      end
    end
  end
end
