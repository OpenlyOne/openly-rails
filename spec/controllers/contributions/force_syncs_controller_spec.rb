# frozen_string_literal: true

require 'controllers/shared_examples/a_force_syncs_controller.rb'

RSpec.describe Contributions::ForceSyncsController, type: :controller do
  let!(:root)   { create :vcs_file_in_branch, :root, branch: branch }
  let!(:folder) { create :vcs_file_in_branch, :folder, parent_in_branch: root }
  let(:branch)        { contribution.branch }
  let(:contribution)  { create :contribution, project: project }
  let(:project) do
    create :project, :setup_complete, :skip_archive_setup, :with_repository
  end
  let(:default_params) do
    {
      profile_handle:   project.owner.to_param,
      project_slug:     project.slug,
      contribution_id:  contribution.id,
      id:               folder.hashed_file_id
    }
  end

  let(:current_account) { contribution.creator.account }
  before do
    project.collaborators << contribution.creator
    sign_in current_account
  end

  it_should_behave_like 'a force syncs controller' do
    let(:redirect_location_when_successful) do
      profile_project_contribution_file_infos_path(
        project.owner, project, contribution, params[:id]
      )
    end
    let(:redirect_location_when_unauthorized) do
      redirect_location_when_successful
    end
    let(:message_when_unauthorized) do
      'You are not authorized to force sync files of this contribution.'
    end
  end
end
