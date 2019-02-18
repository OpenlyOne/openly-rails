# frozen_string_literal: true

require 'controllers/shared_examples/a_redirect_with_success.rb'
require 'controllers/shared_examples/an_authenticated_action.rb'
require 'controllers/shared_examples/an_authorized_action.rb'
require 'controllers/shared_examples/authorizing_project_access.rb'
require 'controllers/shared_examples/raise_404_if_non_existent.rb'
require 'controllers/shared_examples/setting_project.rb'
require 'controllers/shared_examples/successfully_rendering_view.rb'

RSpec.describe Contributions::RepliesController, type: :controller do
  let!(:contribution) { create :contribution }
  let(:project)       { contribution.project }
  let(:master)        { project.master_branch }
  # TODO: Needed for successfully rendering view spec. Otherwise will fail
  #       because calling #link_to_remote on root (which is nil).
  let!(:root)         { create :vcs_file_in_branch, :root, branch: master }
  let(:default_params) do
    {
      profile_handle:   project.owner.to_param,
      project_slug:     project.slug,
      contribution_id:  contribution.id
    }
  end
  let(:current_account) { project.owner.account }
  before                { sign_in current_account }

  describe 'GET #index' do
    let(:params)          { default_params }
    let(:run_request)     { get :index, params: params }

    it_should_behave_like 'setting project'
    it_should_behave_like 'raise 404 if non-existent', Project
    it_should_behave_like 'raise 404 if non-existent', Contribution
    it_should_behave_like 'authorizing project access'

    it 'returns http success' do
      run_request
      expect(response).to have_http_status :success
    end
  end

  describe 'POST #create' do
    let(:add_params)      { { reply: { content: 'new-reply' } } }
    let(:params)          { default_params.merge(add_params) }
    let(:run_request)     { post :create, params: params }

    it_should_behave_like 'an authenticated action'
    it_should_behave_like 'authorizing project access'
    it_should_behave_like 'setting project'
    it_should_behave_like 'raise 404 if non-existent', Project
    it_should_behave_like 'raise 404 if non-existent', Contribution
    it_should_behave_like 'an authorized action' do
      let(:redirect_location) do
        profile_project_contribution_replies_path(
          project.owner, project, contribution
        )
      end
      let(:unauthorized_message) do
        'You are not authorized to reply to this contribution.'
      end
    end

    it_should_behave_like 'a redirect with success' do
      let(:redirect_location) do
        profile_project_contribution_replies_path(
          project.owner, project, contribution
        )
      end
      let(:notice) { 'Reply successfully created.' }
    end

    context 'when creation fails' do
      before do
        allow_any_instance_of(Reply).to receive(:update).and_return(false)
      end

      it_should_behave_like 'successfully rendering view'
    end
  end
end
