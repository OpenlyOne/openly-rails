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
    let(:params)      { { project: { title: 'title', slug: 'slug' } } }
    let(:run_request) { post :create, params: params }
    before            { sign_in create(:account) }

    it_should_behave_like 'an authenticated action'
    it_should_behave_like 'a redirect with success' do
      let(:redirect_location) do
        profile_project_path(controller.current_user, 'slug')
      end
    end

    it 'saves the project' do
      expect_any_instance_of(Project).to receive(:save)
      run_request
    end
  end

  describe 'GET #show' do
    let(:params)      { default_params }
    let(:run_request) { get :show, params: params }

    include_examples 'raise 404 if non-existent', Handle
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
    include_examples 'raise 404 if non-existent', Handle
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
    include_examples 'raise 404 if non-existent', Handle
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
    include_examples 'raise 404 if non-existent', Handle
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
