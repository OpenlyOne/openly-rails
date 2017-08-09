# frozen_string_literal: true

require 'controllers/shared_examples/raise_404_if_non_existent.rb'

RSpec.describe ProjectsController, type: :controller do
  let!(:project)        { create(:project) }
  let(:default_params)  do
    {
      profile_handle: project.owner,
      slug:           project.slug
    }
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
