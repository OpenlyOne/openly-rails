# frozen_string_literal: true

# Expect the action to authorize project access with CanCanCan
RSpec.shared_examples 'authorizing project access' do
  let(:can_access) { false }
  before do
    allow_any_instance_of(Ability).to receive(:can?).and_call_original
    allow_any_instance_of(Ability)
      .to receive(:can?).with(:access, project).and_return can_access
    run_request
  end

  context 'when user can access project' do
    let(:can_access) { true }

    it 'does not have forbidden HTTP status' do
      run_request
      expect(response).not_to have_http_status :forbidden
    end
  end

  context 'when user cannot access project' do
    let(:can_access) { false }

    it 'has forbidden HTTP status with unauthorized message' do
      run_request
      expect(response).to have_http_status :forbidden
      is_expected.to set_flash.now[:alert].to(
        'You are not authorized to access this project.'
      )
    end
  end
end
