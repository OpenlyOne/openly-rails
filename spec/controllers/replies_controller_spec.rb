# frozen_string_literal: true

require 'controllers/shared_examples/a_redirect_with_success.rb'
require 'controllers/shared_examples/an_authenticated_action.rb'
require 'controllers/shared_examples/raise_404_if_non_existent.rb'

RSpec.describe RepliesController, type: :controller do
  let!(:discussion) { create(:discussions_suggestion) }
  let(:project)     { discussion.project }
  let(:default_params) do
    {
      profile_handle:       project.owner,
      project_slug:         project,
      discussion_type:      discussion.type_to_url_segment,
      discussion_scoped_id: discussion
    }
  end

  describe 'GET #index' do
    let(:params)      { default_params }
    let(:run_request) { get :index, params: params }

    it 'redirects to discussions#show' do
      run_request
      expect(response).to have_http_status :redirect
      expect(controller).to redirect_to(
        profile_project_discussion_path(project.owner,
                                        project,
                                        discussion.type_to_url_segment,
                                        discussion)
      )
    end
  end

  describe 'POST #create' do
    let(:add_params) do
      {
        reply: {
          content: 'content'
        }
      }
    end
    let(:params)      { default_params.merge(add_params) }
    let(:run_request) { post :create, params: params }
    before            { sign_in project.owner.account }

    it_should_behave_like 'an authenticated action'
    include_examples 'raise 404 if non-existent', Profiles::Base
    include_examples 'raise 404 if non-existent', Project
    include_examples 'raise 404 if non-existent', Discussions::Base

    it_should_behave_like 'a redirect with success' do
      let(:redirect_location) do
        profile_project_discussion_path(project.owner,
                                        project,
                                        discussion.type_to_url_segment,
                                        discussion)
      end
    end

    it 'saves the discussion' do
      expect_any_instance_of(Reply).to receive(:save)
      run_request
    end
  end
end
