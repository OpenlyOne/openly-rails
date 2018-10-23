# frozen_string_literal: true

require 'controllers/shared_examples/an_authenticated_action.rb'
require 'controllers/shared_examples/an_authorized_action.rb'
require 'controllers/shared_examples/authorizing_project_access.rb'
require 'controllers/shared_examples/setting_project.rb'
require 'controllers/shared_examples/successfully_rendering_view.rb'

RSpec.describe ProjectSetupsController, :delayed_job, type: :controller do
  let!(:project)      { create :project, :skip_archive_setup }
  let(:file_resource) { create :file_resource, :folder }
  let(:link)          { file_resource.external_link }
  let(:default_params) do
    {
      profile_handle: project.owner.to_param,
      project_slug:   project.slug
    }
  end
  let(:current_account) { project.owner.account }
  before                { sign_in current_account }

  describe 'GET #new' do
    let(:params)      { default_params }
    let(:run_request) { get :new, params: params }

    it_should_behave_like 'an authenticated action'
    it_should_behave_like 'setting project'
    it_should_behave_like 'authorizing project access'
    it_should_behave_like 'an authorized action' do
      let(:redirect_location) { profile_project_path(project.owner, project) }
      let(:unauthorized_message) do
        'You are not authorized to set up this project.'
      end
    end

    it 'returns http success' do
      run_request
      expect(response).to have_http_status :success
    end

    context 'when project setup has started or is done' do
      before { project.create_setup(link: link) }

      it 'redirects to :show with notice' do
        run_request
        expect(response).to have_http_status :redirect
        expect(controller).to redirect_to(
          profile_project_setup_path(project.owner, project)
        )
        is_expected.to set_flash[:notice].to(
          'Files are already being imported...'
        )
      end
    end
  end

  describe 'POST #create' do
    let(:params)      { default_params.merge(add_params) }
    let(:run_request) { post :create, params: params }
    let(:add_params) do
      {
        project_setup: {
          link: file_resource.external_link
        }
      }
    end

    it_should_behave_like 'an authenticated action'
    it_should_behave_like 'setting project'
    it_should_behave_like 'authorizing project access'
    it_should_behave_like 'an authorized action' do
      let(:redirect_location) { profile_project_path(project.owner, project) }
      let(:unauthorized_message) do
        'You are not authorized to set up this project.'
      end
    end

    it 'redirects to project setup page with success message' do
      run_request
      expect(response).to redirect_to(
        profile_project_setup_path(project.owner, project)
      )
      is_expected.to set_flash[:notice].to('Files are being imported...')
    end

    it 'calls #begin on setup' do
      expect_any_instance_of(Project::Setup).to receive(:begin)
      run_request
    end

    context 'when #begin fails' do
      before do
        allow_any_instance_of(Project::Setup)
          .to receive(:begin).and_return false
      end

      it_should_behave_like 'successfully rendering view'
    end

    context 'when project setup has started or is done' do
      before { project.create_setup!(link: link) }

      it 'redirects to :show with notice' do
        run_request
        expect(response).to have_http_status :redirect
        expect(controller).to redirect_to(
          profile_project_setup_path(project.owner, project)
        )
        is_expected.to set_flash[:notice].to(
          'Files are already being imported...'
        )
      end
    end
  end

  describe 'GET #show' do
    let(:params)      { default_params }
    let(:run_request) { get :show, params: params }

    before { project.create_setup(link: link) }

    it_should_behave_like 'setting project'
    it_should_behave_like 'authorizing project access'

    it 'returns http success' do
      run_request
      expect(response).to have_http_status :success
    end

    context 'when project setup has not started' do
      before { project.setup.destroy }

      it 'redirects to :new without notice' do
        run_request
        expect(response).to have_http_status :redirect
        expect(controller).to redirect_to(
          new_profile_project_setup_path(project.owner, project)
        )
        is_expected.not_to set_flash[:notice]
      end
    end

    context 'when project setup has completed' do
      before { project.setup.update(is_completed: true) }

      it 'redirects to project with notice' do
        run_request
        expect(response).to have_http_status :redirect
        expect(controller).to redirect_to(
          profile_project_path(project.owner, project)
        )
        is_expected.to set_flash[:notice].to(
          'Setup has been completed.'
        )
      end
    end
  end
end
