# frozen_string_literal: true

require 'controllers/shared_examples/a_redirect_with_success.rb'
require 'controllers/shared_examples/an_authenticated_action.rb'
require 'controllers/shared_examples/an_authorized_action.rb'
require 'controllers/shared_examples/raise_404_if_non_existent.rb'

RSpec.describe ProjectsController, type: :controller do
  let!(:project)        { create(:project) }
  let(:default_params)  do
    {
      profile_handle: project.owner,
      slug:           project.slug
    }
  end

  describe 'GET #new' do
    let(:params)      { nil }
    let(:run_request) { get :new }
    before            { sign_in create(:account) }

    it_should_behave_like 'an authenticated action'

    it 'returns http success' do
      run_request
      expect(response).to have_http_status :success
    end
  end

  describe 'POST #create' do
    let(:params)      { { project: { title: 'title' } } }
    let(:run_request) { post :create, params: params }
    before            { sign_in create(:account) }

    it_should_behave_like 'an authenticated action'
    it_should_behave_like 'a redirect with success' do
      let(:redirect_location) do
        setup_profile_project_path(controller.current_user, 'title')
      end
    end

    it 'saves the project' do
      expect_any_instance_of(Project).to receive(:save)
      run_request
    end
  end

  describe 'GET #setup' do
    let(:params)      { default_params }
    let(:run_request) { get :setup, params: params }
    before            { sign_in project.owner.account }

    it_should_behave_like 'an authenticated action'
    include_examples 'raise 404 if non-existent', Profiles::Base
    include_examples 'raise 404 if non-existent', Project
    it_should_behave_like 'an authorized action' do
      let(:redirect_location) { profile_project_path(project.owner, project) }
    end

    it 'returns http success' do
      run_request
      expect(response).to have_http_status :success
    end

    context 'when root folder exists' do
      before { create :file_items_folder, project: project, parent: nil }
      before { run_request }

      it 'returns http redirect' do
        expect(response).to have_http_status :redirect
        expect(controller).to redirect_to(
          profile_project_path(project.owner, project)
        )
      end

      it 'sets flash notice' do
        expect(@controller).to set_flash[:notice].to(
          'Project has already been set up.'
        )
      end
    end
  end

  describe 'POST #import' do
    before do
      mock_google_drive_requests if ENV['MOCK_GOOGLE_DRIVE_REQUESTS'] == 'true'
    end
    let(:add_params)  { { project: { link_to_google_drive_folder: gdfolder } } }
    let(:gdfolder)    { Settings.google_drive_test_folder }
    let(:params)      { default_params.merge(add_params) }
    let(:run_request) { post :import, params: params }
    before            { sign_in project.owner.account }

    it_should_behave_like 'an authenticated action'
    include_examples 'raise 404 if non-existent', Profiles::Base
    include_examples 'raise 404 if non-existent', Project
    it_should_behave_like 'an authorized action' do
      let(:redirect_location) { profile_project_path(project.owner, project) }
    end
    it_should_behave_like 'a redirect with success' do
      let(:redirect_location) do
        profile_project_path(project.owner, project)
      end
      let(:resource_name) do
        'Google Drive folder'
      end
      let(:inflected_action_name) do
        'imported'
      end
    end

    it 'imports the folder' do
      expect_any_instance_of(Project).to receive(:import_google_drive_folder)
      run_request
    end

    it 'updates the project' do
      expect_any_instance_of(Project).to receive(:update)
      run_request
    end
  end

  describe 'GET #show' do
    let(:params)      { default_params }
    let(:run_request) { get :show, params: params }

    include_examples 'raise 404 if non-existent', Profiles::Base
    include_examples 'raise 404 if non-existent', Project

    it 'returns http success' do
      run_request
      expect(response).to have_http_status :success
    end
  end

  describe 'GET #edit' do
    let(:params)      { default_params }
    let(:run_request) { get :edit, params: params }
    before            { sign_in project.owner.account }

    it_should_behave_like 'an authenticated action'
    include_examples 'raise 404 if non-existent', Profiles::Base
    include_examples 'raise 404 if non-existent', Project
    it_should_behave_like 'an authorized action' do
      let(:redirect_location) { profile_project_path(project.owner, project) }
    end

    it 'returns http success' do
      run_request
      expect(response).to have_http_status :success
    end
  end

  describe 'PATCH #update' do
    let(:add_params)  { { project: { title: 'title', slug: 'new-slug' } } }
    let(:params)      { default_params.merge(add_params) }
    let(:run_request) { put :update, params: params }
    before            { sign_in project.owner.account }

    it_should_behave_like 'an authenticated action'
    include_examples 'raise 404 if non-existent', Profiles::Base
    include_examples 'raise 404 if non-existent', Project
    it_should_behave_like 'an authorized action' do
      let(:redirect_location) { profile_project_path(project.owner, project) }
    end
    it_should_behave_like 'a redirect with success' do
      let(:redirect_location) do
        profile_project_path(project.owner, 'new-slug')
      end
    end

    it 'updates the project' do
      expect_any_instance_of(Project).to receive(:update)
      run_request
    end
  end

  describe 'DELETE #destroy' do
    let(:params)      { default_params }
    let(:run_request) { delete :destroy, params: params }
    before            { sign_in project.owner.account }

    it_should_behave_like 'an authenticated action'
    include_examples 'raise 404 if non-existent', Profiles::Base
    include_examples 'raise 404 if non-existent', Project
    it_should_behave_like 'an authorized action' do
      let(:redirect_location) { profile_project_path(project.owner, project) }
    end
    it_should_behave_like 'a redirect with success' do
      let(:redirect_location) { profile_path(project.owner) }
    end

    it 'destroys the project' do
      expect_any_instance_of(Project).to receive(:destroy)
      run_request
    end

    context 'when destruction of project fails' do
      before do
        allow_any_instance_of(Project).to receive(:destroy).and_return false
      end

      it 'redirects to project' do
        run_request
        expect(response)
          .to redirect_to profile_project_path project.owner, project
      end

      it 'sets flash message' do
        run_request
        is_expected.to set_flash[:alert].to(
          'An unexpected error occured while deleting the project.'
        )
      end
    end
  end
end
