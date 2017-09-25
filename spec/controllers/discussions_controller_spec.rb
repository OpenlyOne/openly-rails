# frozen_string_literal: true

require 'controllers/shared_examples/a_redirect_with_success.rb'
require 'controllers/shared_examples/an_authenticated_action.rb'
require 'controllers/shared_examples/raise_404_if_non_existent.rb'

RSpec.shared_examples 'use DiscussionsController' do |discussion_class|
  describe 'GET #index' do
    let(:params)      { default_params.except :scoped_id }
    let(:run_request) { get :index, params: params }

    include_examples 'raise 404 if non-existent', Handle
    include_examples 'raise 404 if non-existent', Project

    it 'returns http success' do
      run_request
      expect(response).to have_http_status :success
    end
  end

  describe 'GET #new' do
    let(:params)      { default_params.except :scoped_id }
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
        "discussions_#{discussion_type.singularize}": {
          title: 'name'
        }
      }
    end
    let(:params)      { default_params.except(:scoped_id).merge(add_params) }
    let(:run_request) { post :create, params: params }
    before            { sign_in project.owner.account }

    it_should_behave_like 'an authenticated action'
    include_examples 'raise 404 if non-existent', Handle
    include_examples 'raise 404 if non-existent', Project
    it_should_behave_like 'a redirect with success' do
      let(:redirect_location) do
        profile_project_discussion_path(project.owner, project,
                                        discussion_type, Discussions::Base.last)
      end
      let(:resource_name) { discussion_type.singularize.titleize }
    end

    it 'saves the discussion' do
      expect_any_instance_of(discussion_class).to receive(:save)
      run_request
    end
  end

  describe 'GET #show' do
    let(:params)      { default_params }
    let(:run_request) { get :show, params: params }

    include_examples 'raise 404 if non-existent', Handle
    include_examples 'raise 404 if non-existent', Project
    include_examples 'raise 404 if non-existent', discussion_class

    it 'returns http success' do
      run_request
      expect(response).to have_http_status :success
    end
  end
end

RSpec.describe DiscussionsController, type: :controller do
  let!(:project)        { discussion.project }
  let(:discussion_type) { discussion.type_to_url_segment }
  let(:default_params)  do
    {
      profile_handle: project.owner,
      project_slug:   project.slug,
      type:           discussion_type,
      scoped_id:      discussion.scoped_id
    }
  end

  context "when type is 'suggestions'" do
    let(:discussion) { create(:discussions_suggestion) }
    include_examples 'use DiscussionsController', Discussions::Suggestion
  end

  context "when type is 'issues'" do
    let(:discussion) { create(:discussions_issue) }
    include_examples 'use DiscussionsController', Discussions::Issue
  end

  context "when type is 'questions'" do
    let(:discussion) { create(:discussions_question) }
    include_examples 'use DiscussionsController', Discussions::Question
  end
end
