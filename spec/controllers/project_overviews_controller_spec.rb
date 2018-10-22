# frozen_string_literal: true

require 'controllers/shared_examples/authorizing_project_access.rb'
require 'controllers/shared_examples/setting_project.rb'

RSpec.describe ProjectOverviewsController, :delayed_job, type: :controller do
  let!(:project) { create :project, :skip_archive_setup }
  let(:default_params) do
    {
      profile_handle: project.owner.to_param,
      project_slug:   project.slug
    }
  end
  let(:current_account) { project.owner.account }
  before                { sign_in current_account }

  describe 'GET #show' do
    let(:params)      { default_params }
    let(:run_request) { get :show, params: params }

    it_should_behave_like 'setting project'
    it_should_behave_like 'authorizing project access'

    it 'returns http success' do
      run_request
      expect(response).to have_http_status :success
    end
  end
end
