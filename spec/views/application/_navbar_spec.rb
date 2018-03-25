# frozen_string_literal: true

require 'support/helpers/settings_helper.rb'
RSpec.configure do |c|
  c.extend SettingsHelper
end

RSpec.describe 'application/_navbar', type: :view do
  let(:account) { nil }

  before do
    without_partial_double_verification do
      allow(view).to receive(:current_account).and_return account
      allow(view).to receive(:account_signed_in?).and_return account
    end
  end

  it 'has a link to log in' do
    render
    expect(rendered).to have_link 'Login', href: new_session_path
  end

  context 'when registration is enabled' do
    enable_account_registration

    it 'has a link to join' do
      render
      expect(rendered).to have_link('Join', href: new_registration_path)
    end
  end

  context 'when registrations is disabled' do
    disable_account_registration

    it 'does not have a link to join' do
      render
      expect(rendered).not_to have_link('Join')
    end
  end

  context 'when account is signed in' do
    let(:account) { build_stubbed :account }
    let(:user)    { build_stubbed :user }
    let(:count)   { 0 }

    before do
      allow(account).to receive(:user).and_return user
      allow(account).to receive(:unopened_notification_count).and_return count
    end

    it 'has a link to add a project' do
      render
      expect(rendered).to have_link '', href: new_project_path
    end

    it 'has a link to notifications' do
      render
      expect(rendered).to have_link '', href: notifications_path
    end

    it 'has a link to profile' do
      render
      expect(rendered).to have_link '', href: profile_path(account.user)
    end

    it 'has a link to settings' do
      render
      expect(rendered).to have_link '', href: edit_account_path
    end

    it 'has a link to log out' do
      render
      expect(rendered).to have_link '', href: destroy_session_path
    end

    context 'when there are unread notifications' do
      let(:count) { 5 }

      it 'displays # of unread notifications' do
        render
        expect(rendered).to have_text '5'
      end
    end
  end
end
