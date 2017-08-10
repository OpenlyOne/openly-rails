# frozen_string_literal: true

# Expect the action to authorize with CanCanCan
RSpec.shared_examples 'an authorized action' do
  let(:has_ability) { false }
  before do
    allow_any_instance_of(Ability).to receive(:can?).and_return has_ability
    run_request
  end

  it 'rescues from CanCan::AccessDenied' do
    expect(controller).to rescue_from CanCan::AccessDenied
  end

  context 'when user cannot perform action' do
    it { expect(response).to have_http_status :redirect }
    it 'alerts user that they are unauthorized' do
      is_expected.to set_flash[:alert].to(/not authorized/)
    end
    it 'redirects user' do
      expect(response).to redirect_to redirect_location
    end
  end

  context 'when user can perform action' do
    let(:has_ability) { true }
    it 'does not alert user that they are unauthorized' do
      is_expected.not_to set_flash[:alert].to(/not authorized/)
    end
  end
end
