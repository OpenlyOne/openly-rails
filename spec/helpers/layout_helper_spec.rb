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

    context 'when controller_name or action_name includes hyphens' do
      before do
        allow(controller).to receive(:controller_name).and_return('a_b_c')
        allow(controller).to receive(:action_name).and_return('d_e_f')
      end

      it 'replaces them with dashes' do
        expect(helper.controller_action_identifier).to eq 'c-a-b-c a-d-e-f'
      end
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
end
