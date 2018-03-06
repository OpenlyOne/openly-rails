# frozen_string_literal: true

require 'controllers/shared_examples/a_redirect_with_success.rb'
require 'controllers/shared_examples/an_authenticated_action.rb'
require 'controllers/shared_examples/an_authorized_action.rb'
require 'controllers/shared_examples/raise_404_if_non_existent.rb'
require 'controllers/shared_examples/successfully_rendering_view.rb'

RSpec.describe RevisionsController, type: :controller do
  let!(:project)        { create :project }
  let(:default_params)  do
    {
      profile_handle: project.owner.to_param,
      project_slug:   project.slug
    }
  end

  describe 'GET #index' do
    let(:params)      { default_params }
    let(:run_request) { get :index, params: params }

    it_should_behave_like 'raise 404 if non-existent', Profiles::Base
    it_should_behave_like 'raise 404 if non-existent', Project

    it 'returns http success' do
      run_request
      expect(response).to have_http_status :success
    end
  end

  describe 'GET #new' do
    let(:params)      { default_params }
    let(:run_request) { get :new, params: params }
    before            { sign_in project.owner.account }

    it_should_behave_like 'an authenticated action'
    it_should_behave_like 'raise 404 if non-existent', Profiles::Base
    it_should_behave_like 'raise 404 if non-existent', Project
    it_should_behave_like 'an authorized action' do
      let(:redirect_location) { profile_project_path(project.owner, project) }
      let(:unauthorized_message) do
        'You are not authorized to commit changes for this project.'
      end
    end

    it 'returns http success' do
      run_request
      expect(response).to have_http_status :success
    end
  end

  describe 'POST #create' do
    let!(:revision_draft) { create :revision, project: project, author: author }
    let(:author)          { project.owner }
    let(:params)          { default_params.merge(add_params) }
    let(:run_request)     { post :create, params: params }
    before                { sign_in project.owner.account }
    let(:add_params) do
      {
        revision: {
          title: 'Initial Commit',
          id: revision_draft.id
        }
      }
    end

    it_should_behave_like 'an authenticated action'
    it_should_behave_like 'raise 404 if non-existent', Profiles::Base
    it_should_behave_like 'raise 404 if non-existent', Project
    it_should_behave_like 'an authorized action' do
      let(:redirect_location) { profile_project_path(project.owner, project) }
      let(:unauthorized_message) do
        'You are not authorized to commit changes for this project.'
      end
    end

    it_should_behave_like 'a redirect with success' do
      let(:redirect_location) do
        profile_project_root_folder_path(project.owner, project)
      end
    end

    it 'publishes the revision' do
      expect_any_instance_of(Revision)
        .to receive(:update).with(hash_including(is_published: true))
      run_request
    end

    context 'when creation fails' do
      before do
        allow_any_instance_of(Revision).to receive(:update).and_return false
      end

      it_should_behave_like 'successfully rendering view'
    end
  end
end
