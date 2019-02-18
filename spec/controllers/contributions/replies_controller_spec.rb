# frozen_string_literal: true

require 'controllers/shared_examples/authorizing_project_access.rb'
require 'controllers/shared_examples/raise_404_if_non_existent.rb'
require 'controllers/shared_examples/setting_project.rb'

RSpec.describe Contributions::RepliesController, type: :controller do
  let!(:contribution) { create :contribution }
  let(:project)       { contribution.project }
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
end
