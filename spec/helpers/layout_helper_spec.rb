# frozen_string_literal: true

require 'support/helpers/settings_helper.rb'
RSpec.configure do |c|
  c.extend SettingsHelper
end

RSpec.describe LayoutHelper, type: :helper do
  describe '#controller_action_identifier' do
    before do
      allow(controller).to receive(:controller_name).and_return('accounts')
      allow(controller).to receive(:action_name).and_return('create')
    end

    it 'includes the controller name with c- prefix' do
      expect(helper.controller_action_identifier).to include 'c-accounts'
    end

    it 'includes the action name with a- prefix' do
      expect(helper.controller_action_identifier).to include 'a-create'
    end
  end

  describe '#color_scheme' do
    it "includes 'color-scheme'" do
      expect(helper.color_scheme).to include 'color-scheme'
    end

    it "includes the base color with 'primary-___'" do
      expect(helper.color_scheme).to match(/\bprimary-[a-z]+\b/)
    end

    it "includes the text color with 'primary-___-text'" do
      expect(helper.color_scheme).to match(/\bprimary-(white|black)-text\b/)
    end
  end

  describe '#navigation_links' do
    let(:included_paths) { helper.navigation_links.map { |link| link[:path] } }

    before do
      allow(helper).to receive(:account_signed_in?).and_return(login_status)
    end

    context 'when user is signed in' do
      let(:login_status) { true }
      let(:account) { create(:account) }
      before { allow(helper).to receive(:current_account).and_return(account) }

      it 'includes a link to profile' do
        expect(included_paths).to include user_path(account.user)
      end

      it 'includes a link to account' do
        expect(included_paths).to include edit_account_path
      end

      it 'includes a link to logout' do
        expect(included_paths).to include destroy_session_path
      end
    end

    context 'when user is signed out' do
      let(:login_status) { false }

      context 'when registration is enabled' do
        enable_account_registration

        it 'includes a link to join' do
          expect(included_paths).to include new_registration_path
        end
      end

      context 'when registration is disabled' do
        disable_account_registration

        it 'does not raise an error' do
          expect { included_paths }.not_to raise_error
        end
      end

      it 'includes a link to login' do
        expect(included_paths).to include new_session_path
      end
    end
  end
end
