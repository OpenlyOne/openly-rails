# frozen_string_literal: true

RSpec.describe ProfilesController, type: :controller do
  describe 'GET #show' do
    context 'when handle exists' do
      let!(:handle) { create(:handle) }

      it 'returns http success' do
        get :show, params: { handle: handle.identifier }
        expect(response).to have_http_status(:success)
      end
    end

    context 'when handle does not exist' do
      let!(:handle) { build(:handle) }

      it 'raises record not found error' do
        expect do
          get :show, params: { handle: handle.identifier }
        end.to raise_error ActiveRecord::RecordNotFound
      end
    end
  end
end
