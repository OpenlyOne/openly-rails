# frozen_string_literal: true

require 'controllers/shared_examples/an_authenticated_action.rb'
require 'controllers/shared_examples/an_authorized_action.rb'
require 'controllers/shared_examples/authorizing_project_access.rb'
require 'controllers/shared_examples/raise_404_if_non_existent.rb'
require 'controllers/shared_examples/setting_project.rb'

RSpec.describe FileRestoresController, type: :controller do
  let!(:root) do
    create :vcs_file_in_branch, :root, branch: project.master_branch
  end
  let!(:file)   { create :vcs_file_in_branch, parent_in_branch: root }
  let(:version) { file.current_version }
  let(:project) { create :project, :setup_complete, :skip_archive_setup }
  let(:default_params) do
    {
      profile_handle: project.owner.to_param,
      project_slug:   project.slug,
      id:             version.id
    }
  end

  let(:current_account) { project.owner.account }
  before                { sign_in current_account }

  describe 'POST #create' do
    let(:params)      { default_params }
    let(:run_request) { post :create, params: params }

    let(:restorer) { instance_double VCS::Operations::FileRestore }

    before do
      allow(VCS::Operations::FileRestore).to receive(:new).and_return restorer
      allow(restorer).to receive(:restore)
    end

    it_should_behave_like 'an authenticated action'
    it_should_behave_like 'setting project where setup is complete'
    it_should_behave_like 'raise 404 if non-existent', nil do
      # when file does not exist and never has
      before { default_params[:id] = 'some-nonexistent-id' }
    end
    it_should_behave_like 'an authorized action' do
      let(:redirect_location) do
        profile_project_file_infos_path(project.owner, project, version.file)
      end
      let(:unauthorized_message) do
        'You are not authorized to restore files of this project.'
      end
    end
    it_should_behave_like 'authorizing project access'

    it 'redirects to file infos page with success message' do
      run_request
      expect(response).to redirect_to(
        profile_project_file_infos_path(project.owner, project, version.file)
      )
      is_expected.to set_flash[:notice].to 'File successfully restored.'
    end

    it 'calls #restore on file restorer' do
      run_request
      expect(VCS::Operations::FileRestore)
        .to have_received(:new)
        .with(version: version, target_branch: project.master_branch)
      expect(restorer).to have_received(:restore)
    end
  end
end
