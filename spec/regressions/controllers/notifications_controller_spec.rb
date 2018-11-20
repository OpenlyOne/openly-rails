# frozen_string_literal: true

RSpec.describe NotificationsController, type: :controller do
  let(:current_account) { create :account }
  before                { sign_in current_account }

  describe 'GET #index' do
    let(:run_request) { get :index }

    let(:relation) { instance_double ActiveRecord::Relation }

    before do
      allow(Notification).to receive(:where).and_return relation
      allow(relation).to receive(:order).and_return relation
      allow(relation).to receive(:includes)
    end

    it 'orders notifications in descending order' do
      run_request
      expect(relation).to have_received(:order).with(id: :desc)
    end
  end
end
