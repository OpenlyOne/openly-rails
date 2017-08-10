# frozen_string_literal: true

require 'controllers/shared_examples/an_authenticated_action.rb'
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

    it 'saves the project' do
      expect_any_instance_of(Project).to receive(:save)
      run_request
    end

    it 'redirects to project' do
      run_request
      expect(response)
        .to redirect_to profile_project_path(controller.current_user, 'slug')
    end

    it 'sets flash message' do
      run_request
      is_expected.to set_flash[:notice].to 'Project successfully created.'
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
end
