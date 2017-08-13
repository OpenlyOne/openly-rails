# frozen_string_literal: true

require 'controllers/shared_examples/raise_404_if_non_existent.rb'

RSpec.describe ProfilesController, type: :controller do
  let!(:handle)         { create(:handle) }
  let(:default_params)  do
    {
      handle: handle.identifier
    }
  end

  describe 'GET #show' do
    let(:params)      { default_params }
    let(:run_request) { get :show, params: params }

    include_examples 'raise 404 if non-existent', Handle

    it 'returns http success' do
      run_request
      expect(response).to have_http_status :success
    end
  end
end
