# frozen_string_literal: true

require 'controllers/shared_examples/a_redirect_with_success.rb'
require 'controllers/shared_examples/an_authenticated_action.rb'

RSpec.describe AccountsController, type: :controller do
  include Devise::Test::ControllerHelpers

  let!(:account)        { create :account, password: 'password' }
  let(:default_params)  { {} }

  before do
    @request.env['devise.mapping'] = Devise.mappings[:account]
    sign_in account
  end

  describe 'GET #edit' do
    let(:params)      { default_params }
    let(:run_request) { get :edit, params: params }

    it_should_behave_like 'an authenticated action'

    it 'returns http success' do
      run_request
      expect(response).to have_http_status :success
    end
  end

  describe 'PATCH #update' do
    let(:add_params) do
      {
        account: {
          current_password: 'password',
          password: 'new-password',
          password_confirmation: 'new-password'
        }
      }
    end
    let(:params)      { default_params.merge(add_params) }
    let(:run_request) { patch :update, params: params }

    it_should_behave_like 'an authenticated action'
    it_should_behave_like 'a redirect with success' do
      let(:redirect_location) { account_root_path }
      let(:notice) do
        'Your account has been updated successfully.'
      end
    end

    it 'updates the account' do
      run_request
      expect(account.reload).to be_valid_password('new-password')
    end

    context 'when current password is incorrect' do
      before { add_params[:account][:current_password] = 'passw0rd' }

      it 'does not update the account' do
        run_request
        expect(account.reload).not_to be_valid_password('new-password')
      end
    end

    context 'when trying to change email' do
      before { add_params[:account][:email] = 'new@email.com' }

      it 'does not update the email address' do
        run_request
        expect(account.reload.email).not_to eq 'new@email.com'
      end
    end
  end
end
