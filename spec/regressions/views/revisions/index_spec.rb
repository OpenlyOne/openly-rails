# frozen_string_literal: true

RSpec.describe 'revisions/index', type: :view do
  let(:project)     { build_stubbed :project }
  let(:revisions)   { build_stubbed_list :revision, 3 }
  let(:snapshots)   { build_stubbed_list(:file_resource_snapshot, 3) }
  let(:diffs) do
    snapshots.map do |snapshot|
      FileDiff.new(file_resource_id: 12,
                   current_snapshot: snapshot,
                   first_three_ancestors: [])
    end
  end

  before do
    assign(:project, project)
    assign(:revisions, revisions)
    controller.request.path_parameters[:profile_handle] = project.owner.to_param
    controller.request.path_parameters[:project_slug] = project.to_param

    root = instance_double FileResource
    allow(project).to receive(:root_folder).and_return root
    allow(root).to receive(:provider).and_return Providers::GoogleDrive
    allow(revisions.first).to receive(:file_diffs).and_return diffs
  end

  context 'rendering PDF documents' do
    let(:snapshots) { build_stubbed_list(:file_resource_snapshot, 3, :pdf) }

    it 'does not raise an error' do
      render
      snapshots.each do |snapshot|
        expect(rendered).to have_text snapshot.name
      end
    end
  end
end
