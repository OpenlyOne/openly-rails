# frozen_string_literal: true

require 'controllers/shared_examples/an_authenticated_action.rb'
require 'controllers/shared_examples/raise_404_if_non_existent.rb'
require 'support/helpers/notifications_helper.rb'

RSpec.describe NotificationsController, type: :controller do
  include NotificationsHelper

  let(:current_account) { create :account }
  before                { sign_in current_account }

  describe 'GET #index' do
    let(:run_request) { get :index }

    it_should_behave_like 'an authenticated action'

    it 'returns http success' do
      run_request
      expect(response).to have_http_status :success
    end
  end

  describe 'GET #show' do
    let!(:notification) do
      create(random_notification_factory, target: current_account)
    end
    let(:run_request) { get :show, params: { id: notification.id } }

    it_should_behave_like 'an authenticated action'
    it_should_behave_like 'raise 404 if non-existent', Notification

    it 'marks notifications as read' do
      expect_any_instance_of(ActivityNotification::Notification)
        .to receive(:open!)
      run_request
    end

    it 'returns http redirect' do
      run_request
      expect(response).to have_http_status :redirect
    end

    context 'when notification target is not current account' do
      let(:notification) { create(random_notification_factory) }

      it 'raises 404' do
        expect { run_request }.to raise_error ActiveRecord::RecordNotFound
      end
    end
  end
end
