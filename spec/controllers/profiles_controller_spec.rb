# frozen_string_literal: true

require 'controllers/shared_examples/a_redirect_with_success.rb'
require 'controllers/shared_examples/an_authenticated_action.rb'
require 'controllers/shared_examples/an_authorized_action.rb'
require 'controllers/shared_examples/raise_404_if_non_existent.rb'

RSpec.describe ProfilesController, type: :controller do
  let!(:profile)        { create :user }
  let!(:handle)         { profile.handle }
  let(:default_params)  do
    {
      handle: handle
    }
  end

  describe 'GET #show' do
    let(:params)      { default_params }
    let(:run_request) { get :show, params: params }

    it_should_behave_like 'raise 404 if non-existent', Profiles::Base

    it 'returns http success' do
      run_request
      expect(response).to have_http_status :success
    end
  end

  describe 'GET #edit' do
    let(:params)      { default_params }
    let(:run_request) { get :edit, params: params }
    before            { sign_in profile.account }

    it_should_behave_like 'an authenticated action'
    it_should_behave_like 'raise 404 if non-existent', Profiles::Base
    it_should_behave_like 'an authorized action' do
      let(:redirect_location) { profile_path(profile) }
      let(:unauthorized_message) do
        'You are not authorized to edit this profile.'
      end
    end

    it 'returns http success' do
      run_request
      expect(response).to have_http_status :success
    end
  end

  describe 'PATCH #update' do
    let(:add_params)  { { profiles_base: { name: 'name', about: 'about' } } }
    let(:params)      { default_params.merge(add_params) }
    let(:run_request) { patch :update, params: params }
    before            { sign_in profile.account }

    it_should_behave_like 'an authenticated action'
    it_should_behave_like 'raise 404 if non-existent', Profiles::Base
    it_should_behave_like 'an authorized action' do
      let(:redirect_location) { profile_path(profile) }
    end

    it_should_behave_like 'a redirect with success' do
      let(:redirect_location) { profile_path(profile) }
    end

    it 'updates the profile' do
      expect_any_instance_of(Profiles::Base).to receive(:update)
      run_request
    end
  end
end
