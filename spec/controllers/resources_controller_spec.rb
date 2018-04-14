# frozen_string_literal: true

require 'controllers/shared_examples/raise_404_if_non_existent.rb'

RSpec.describe ResourcesController, type: :controller do
  describe 'GET #show' do
    let!(:resource)   { create :resource }
    let(:run_request) { get :show, params: { id: resource.id } }

    it_should_behave_like 'raise 404 if non-existent', Resource

    it 'returns http redirect' do
      run_request
      expect(response).to have_http_status :redirect
    end
  end
end
