# frozen_string_literal: true

RSpec.describe ErrorsController, type: :controller do
  describe '#not_found' do
    it 'returns http status 404' do
      get :not_found
      expect(response).to have_http_status 404
    end
  end

  describe '#unacceptable' do
    it 'returns http status 422' do
      get :unacceptable
      expect(response).to have_http_status 422
    end
  end

  describe '#internal_server_error' do
    it 'returns http status 500' do
      get :internal_server_error
      expect(response).to have_http_status 500
    end
  end
end
