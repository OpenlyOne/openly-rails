# frozen_string_literal: true

RSpec.describe VCS::Operations::ContentChangeFragment, type: :model do
  describe '#paragraph_break?' do
    subject(:fragment) { described_class::Retain.new(content: content) }

    let(:content) { "\n\n" }

    it { is_expected.to be_paragraph_break }

    context 'when content is not line break' do
      let(:content) { 'apple juice' }

      it { is_expected.not_to be_paragraph_break }
    end

    context 'when content is not an exact line break' do
      let(:content) { "\n\nbb" }

      it { is_expected.not_to be_paragraph_break }
    end
  end
end
