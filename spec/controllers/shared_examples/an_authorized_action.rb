# frozen_string_literal: true

# Expect the action to authorize with CanCanCan
RSpec.shared_examples 'an authorized action' do
  let(:has_ability) { false }
  before do
    allow(controller).to receive(:authorize!).and_call_original
    allow(controller).to receive(:authorize!).with(:access, any_args)
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
      # Flash message should not contain underscores or forward slashes.
      # Set a custom message in config/locales/en.yml
      if defined?(unauthorized_message)
        is_expected.to set_flash[:alert].to unauthorized_message
      else
        is_expected.not_to set_flash[:alert].to %r{[_/]}
      end
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
