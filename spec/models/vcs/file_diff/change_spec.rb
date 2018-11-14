# frozen_string_literal: true

RSpec.describe VCS::FileDiff::Change, type: :model do
  subject(:change)  { described_class.new(diff: diff) }
  let(:diff)        { instance_double VCS::FileDiff }

  describe 'parent class methods' do
    it { is_expected.to respond_to(:color) }
    it { is_expected.to respond_to(:id) }
    it { is_expected.to respond_to(:text_color) }
    it { is_expected.to respond_to(:type) }
    it { is_expected.to respond_to(:selected?) }
    it { is_expected.to respond_to(:select!) }
    it { is_expected.to respond_to(:unselect!) }
    it { is_expected.to be_respond_to(:color_shade, true) }
    it { is_expected.to be_respond_to(:tooltip_base_text, true) }
  end
end
