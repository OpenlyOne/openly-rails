# frozen_string_literal: true

require 'controllers/shared_examples/a_redirect_with_success.rb'
require 'controllers/shared_examples/an_authenticated_action.rb'
require 'controllers/shared_examples/an_authorized_action.rb'
require 'controllers/shared_examples/authorizing_project_access.rb'
require 'controllers/shared_examples/raise_404_if_non_existent.rb'
require 'controllers/shared_examples/setting_project.rb'
require 'controllers/shared_examples/successfully_rendering_view.rb'

RSpec.describe ContributionsController, type: :controller do
  let!(:project)      { create :project, :setup_complete, :skip_archive_setup }
  let(:master_branch) { project.master_branch }
  let(:default_params) do
    {
      profile_handle: project.owner.to_param,
      project_slug:   project.slug
    }
  end
  let(:current_account) { project.owner.account }
  before                { sign_in current_account }

  describe 'GET #index' do
    let(:params)      { default_params }
    let(:run_request) { get :index, params: params }

    it_should_behave_like 'raise 404 if non-existent', Project
    it_should_behave_like 'authorizing project access'

    it 'returns http success' do
      run_request
      expect(response).to have_http_status :success
    end
  end

  describe 'GET #new' do
    let(:params)      { default_params }
    let(:run_request) { get :new, params: params }

    it_should_behave_like 'an authenticated action'
    it_should_behave_like 'raise 404 if non-existent', Project
    it_should_behave_like 'an authorized action' do
      let(:redirect_location) do
        profile_project_contributions_path(project.owner, project)
      end
      let(:unauthorized_message) do
        'You are not authorized to create contributions in this project.'
      end
    end
    it_should_behave_like 'authorizing project access'

    it 'returns http success' do
      run_request
      expect(response).to have_http_status :success
    end
  end

  describe 'POST #create' do
    let(:author)          { current_account.user }
    let(:params)          { default_params.merge(add_params) }
    let(:run_request)     { post :create, params: params }
    let(:add_params) do
      {
        contribution: {
          title: 'New Contribution',
          description: 'Here is the description.'
        }
      }
    end

    it_should_behave_like 'an authenticated action'
    it_should_behave_like 'raise 404 if non-existent', Project
    it_should_behave_like 'an authorized action' do
      let(:redirect_location) do
        profile_project_contributions_path(project.owner, project)
      end
      let(:unauthorized_message) do
        'You are not authorized to create contributions in this project.'
      end
    end

    it_should_behave_like 'a redirect with success' do
      let(:contribution) { Contribution.first }
      let(:redirect_location) do
        profile_project_contribution_path(project.owner, project, contribution)
      end
    end
    it_should_behave_like 'authorizing project access'

    it 'saves the contribution' do
      expect_any_instance_of(Contribution).to receive(:save)
      run_request
    end
  end

  describe 'GET #show' do
    let!(:contribution) { create :contribution, project: project }
    let(:params)        { default_params.merge(add_params) }
    let(:run_request)   { get :show, params: params }
    let(:add_params)    { { id: contribution.id } }

    it_should_behave_like 'raise 404 if non-existent', Project
    it_should_behave_like 'raise 404 if non-existent', Contribution
    it_should_behave_like 'authorizing project access'

    it 'returns http success' do
      run_request
      expect(response).to have_http_status :success
    end
  end
end
