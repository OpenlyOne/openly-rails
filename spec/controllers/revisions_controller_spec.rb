# frozen_string_literal: true

require 'controllers/shared_examples/a_redirect_with_success.rb'
require 'controllers/shared_examples/a_repository_locking_action.rb'
require 'controllers/shared_examples/an_authenticated_action.rb'
require 'controllers/shared_examples/an_authorized_action.rb'
require 'controllers/shared_examples/raise_404_if_non_existent.rb'

RSpec.describe RevisionsController, type: :controller do
  let!(:project)        { create :project }
  let(:default_params)  do
    {
      profile_handle: project.owner.to_param,
      project_slug:   project.slug
    }
  end

  describe 'GET #new' do
    let(:params)      { default_params }
    let(:run_request) { get :new, params: params }
    before            { sign_in project.owner.account }

    it_should_behave_like 'an authenticated action'
    include_examples 'raise 404 if non-existent', Profiles::Base
    include_examples 'raise 404 if non-existent', Project
    it_should_behave_like 'an authorized action' do
      let(:redirect_location) { profile_project_path(project.owner, project) }
      let(:unauthorized_message) do
        'You are not authorized to commit changes for this project.'
      end
    end
    it_should_behave_like 'a repository locking action'

    it 'returns http success' do
      run_request
      expect(response).to have_http_status :success
    end
  end

  describe 'POST #create' do
    let!(:revision_draft) { project.repository.build_revision }
    let(:params)          { default_params.merge(add_params) }
    let(:run_request)     { post :create, params: params }
    before                { sign_in project.owner.account }
    let(:add_params) do
      {
        revision: {
          summary: 'Initial Commit',
          tree_id: revision_draft.tree_id
        }
      }
    end

    it_should_behave_like 'an authenticated action'
    include_examples 'raise 404 if non-existent', Profiles::Base
    include_examples 'raise 404 if non-existent', Project
    it_should_behave_like 'an authorized action' do
      let(:redirect_location) { profile_project_path(project.owner, project) }
      let(:unauthorized_message) do
        'You are not authorized to commit changes for this project.'
      end
    end
    it_should_behave_like 'a repository locking action'

    it_should_behave_like 'a redirect with success' do
      let(:redirect_location) do
        profile_project_root_folder_path(project.owner, project)
      end
    end

    it 'commits the changes' do
      expect_any_instance_of(VersionControl::Revisions::Drafted)
        .to receive(:commit)
      run_request
    end
  end
end
