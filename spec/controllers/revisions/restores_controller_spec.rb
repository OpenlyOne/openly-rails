# frozen_string_literal: true

require 'controllers/shared_examples/an_authenticated_action.rb'
require 'controllers/shared_examples/an_authorized_action.rb'
require 'controllers/shared_examples/authorizing_project_access.rb'
require 'controllers/shared_examples/raise_404_if_non_existent.rb'
require 'controllers/shared_examples/setting_project.rb'

RSpec.describe Revisions::RestoresController, type: :controller do
  let!(:root) do
    create :vcs_file_in_branch, :root, branch: project.master_branch
  end
  let!(:revision) { create :vcs_commit, branch: project.master_branch }
  let(:project)   { create :project, :setup_complete, :skip_archive_setup }
  let(:default_params) do
    {
      profile_handle: project.owner.to_param,
      project_slug:   project.slug,
      revision_id:    revision.id
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
      before { default_params[:revision_id] = 'some-nonexistent-id' }
    end
    it_should_behave_like 'an authorized action' do
      let(:redirect_location) do
        profile_project_revisions_path(project.owner, project)
      end
      let(:unauthorized_message) do
        'You are not authorized to restore revisions of this project.'
      end
    end
    it_should_behave_like 'authorizing project access'

    it 'redirects to files page with success message' do
      run_request
      expect(response).to redirect_to(
        restore_status_profile_project_revisions_path(
          project.owner, project
        )
      )
      is_expected.to set_flash[:notice].to 'Revision is being restored...'
    end
  end

  describe 'GET #show' do
    let(:params)          { default_params.except(:revision_id) }
    let(:run_request)     { get :show, params: params }
    let(:jobs_remaining)  { %i[j1 j2 j3] }

    it_should_behave_like 'an authenticated action'
    it_should_behave_like 'setting project where setup is complete'
    it_should_behave_like 'an authorized action' do
      let(:redirect_location) do
        profile_project_revisions_path(project.owner, project)
      end
      let(:unauthorized_message) do
        'You are not authorized to restore revisions of this project.'
      end
    end
    it_should_behave_like 'authorizing project access'

    before do
      allow(Delayed::Job).to receive(:where).and_call_original
      allow(Delayed::Job)
        .to receive(:where)
        .with(hash_including(queue: :file_restore))
        .and_return jobs_remaining
    end

    it 'returns http success' do
      run_request
      expect(response).to have_http_status :success
    end

    context 'when all jobs are processed' do
      let(:jobs_remaining) { [] }

      it 'redirects to files page with success message' do
        run_request
        expect(response).to redirect_to(
          profile_project_root_folder_path(
            project.owner, project
          )
        )
        is_expected.to set_flash[:notice].to 'Revision successfully restored.'
      end
    end
  end
end
