# frozen_string_literal: true

# Expect the controller action to authenticate the user account
RSpec.shared_examples 'an authenticated action' do
  context 'when user is not authenticated' do
    before do
      sign_out :account
      run_request
    end

    it 'redirects to new session path' do
      expect(response).to have_http_status :redirect
      expect(controller).to redirect_to new_session_path
    end

    it 'alerts user that login is required' do
      is_expected.to set_flash[:alert].to(/log in/)
    end
  end
end
