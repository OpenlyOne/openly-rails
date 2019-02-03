# frozen_string_literal: true

require 'controllers/shared_examples/a_force_syncs_controller.rb'

RSpec.describe ForceSyncsController, type: :controller do
  let!(:root)   { create :vcs_file_in_branch, :root, branch: master_branch }
  let!(:folder) { create :vcs_file_in_branch, :folder, parent_in_branch: root }
  let(:master_branch) { project.master_branch }
  let(:project) do
    create :project, :setup_complete, :skip_archive_setup, :with_repository
  end
  let(:default_params) do
    {
      profile_handle: project.owner.to_param,
      project_slug:   project.slug,
      id:             folder.hashed_file_id
    }
  end

  let(:current_account) { project.owner.account }
  before                { sign_in current_account }

  it_should_behave_like 'a force syncs controller' do
    let(:redirect_location_when_successful) do
      profile_project_file_infos_path(project.owner, project, params[:id])
    end
    let(:redirect_location_when_unauthorized) do
      redirect_location_when_successful
    end
    let(:message_when_unauthorized) do
      'You are not authorized to force sync files of this project.'
    end
  end
end
