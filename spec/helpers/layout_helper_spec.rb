# frozen_string_literal: true

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
end
