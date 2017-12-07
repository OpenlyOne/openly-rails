# frozen_string_literal: true

RSpec.describe SignupsController, type: :controller do
  describe 'POST #create' do
    let(:params)      { { signup: { email: 'test@email.com' } } }
    let(:run_request) { post :create, params: params }

    it 'returns http success' do
      run_request
      expect(response).to have_http_status :success
    end
  end
end
