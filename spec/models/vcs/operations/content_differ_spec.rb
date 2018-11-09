# frozen_string_literal: true

RSpec.describe VCS::Operations::ContentDiffer, type: :model do
  subject(:differ) do
    described_class.new(new_content: new_content, old_content: old_content)
  end

  let(:new_content) { 'Hello, my name is Lara.' }
  let(:old_content) { 'Hi, my last name is Long.' }

  describe '.escape(content)' do
    subject(:escaped) { described_class.escape(content) }

    let(:content) { '{++ok--}' }

    it { is_expected.to eq '{\\+\\+ok\\-\\-}' }
  end

  describe '.unescape(content)' do
    subject(:unescaped) { described_class.unescape(content) }

    let(:content) { '{\\+\\+ok\\-\\-}' }

    it { is_expected.to eq '{++ok--}' }
  end

  describe '#full' do
    subject(:full) { differ.full }

    before do
      allow(described_class)
        .to receive(:change).with('new', 'old').and_return 'change'
      allow(differ).to receive(:new_content).and_return 'new'
      allow(differ).to receive(:old_content).and_return 'old'
    end

    it { is_expected.to eq 'change' }
  end
end
