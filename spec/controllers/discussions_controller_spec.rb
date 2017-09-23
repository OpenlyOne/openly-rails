# frozen_string_literal: true

require 'controllers/shared_examples/a_redirect_with_success.rb'
require 'controllers/shared_examples/an_authenticated_action.rb'
require 'controllers/shared_examples/raise_404_if_non_existent.rb'

RSpec.describe DiscussionsController, type: :controller do
  let!(:discussion)     { create(:discussions_suggestion) }
  let!(:project)        { discussion.project }
  let(:default_params)  do
    {
      profile_handle: project.owner,
      project_slug:   project.slug,
      type:           'suggestions', # discussion.type_to_url_segment
      id:             discussion.id
    }
  end

  describe 'GET #index' do
    let(:params)      { default_params.except :id }
    let(:run_request) { get :index, params: params }

    include_examples 'raise 404 if non-existent', Handle
    include_examples 'raise 404 if non-existent', Project

    it 'returns http success' do
      run_request
      expect(response).to have_http_status :success
    end
  end

  describe 'GET #new' do
    let(:params)      { default_params.except :id }
    let(:run_request) { get :new, params: params }
    before            { sign_in project.owner.account }

    it_should_behave_like 'an authenticated action'
    include_examples 'raise 404 if non-existent', Handle
    include_examples 'raise 404 if non-existent', Project

    it 'returns http success' do
      run_request
      expect(response).to have_http_status :success
    end
  end

  describe 'POST #create' do
    let(:add_params) do
      {
        discussions_suggestion: {
          title: 'name'
        }
      }
    end
    let(:params)      { default_params.except(:id).merge(add_params) }
    let(:run_request) { post :create, params: params }
    before            { sign_in project.owner.account }

    it_should_behave_like 'an authenticated action'
    include_examples 'raise 404 if non-existent', Handle
    include_examples 'raise 404 if non-existent', Project
    it_should_behave_like 'a redirect with success' do
      let(:redirect_location) do
        new_profile_project_discussion_path(
          project.owner,
          project,
          'suggestions'
        )
      end
      let(:resource_name) { 'Suggestion' }
    end

    it 'saves the discussion' do
      expect_any_instance_of(Discussions::Suggestion).to receive(:save)
      run_request
    end
  end
end
