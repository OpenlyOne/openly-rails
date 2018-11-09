# frozen_string_literal: true

RSpec.describe VCS::Operations::ContentChangeFragment, type: :model do
  subject(:change_fragment) { described_class.new(fragment) }

  let(:fragment) { 'a fragment' }

  describe '#addition?' do
    it { is_expected.not_to be_addition }

    context 'when fragment starts with {++ and ends with ++}' do
      let(:fragment) { '{++a fragment++}' }

      it { is_expected.to be_addition }
    end
  end

  describe '#content' do
    subject(:content) { change_fragment.content }

    context 'when fragment has delimiters' do
      let(:fragment) { '{++A COOL fragment++}' }

      it { is_expected.to eq 'A COOL fragment' }
    end

    context 'when fragment has escaped content' do
      let(:fragment) { 'HELL\\+LO\\-\\-OK' }

      it { is_expected.to eq 'HELL+LO--OK' }
    end

    context 'when fragment is escaped and delimited' do
      let(:fragment) { '{--HEY\\+\\-OK--}' }

      it { is_expected.to eq 'HEY+-OK' }
    end
  end

  describe 'truncated_content(num_chars)' do
    subject(:truncated_content) { change_fragment.truncated_content(num_chars) }

    let(:num_chars)     { 3 }
    let(:fragment)      { 'abcdefghijklmnopqrstuvwxyz' }
    let(:is_beginning)  { false }
    let(:is_ending)     { false }
    let(:is_middle)     { false }

    before do
      allow(change_fragment).to receive(:beginning?).and_return is_beginning
      allow(change_fragment).to receive(:ending?).and_return is_ending
      allow(change_fragment).to receive(:middle?).and_return is_middle
    end

    context 'when beginning' do
      let(:is_beginning) { true }

      it { is_expected.to eq '...xyz' }
    end

    context 'when ending' do
      let(:is_ending) { true }

      it { is_expected.to eq 'abc...' }
    end

    context 'when middle' do
      let(:is_middle) { true }

      it { is_expected.to eq 'abc...xyz' }
    end
  end

  describe '#deletion?' do
    it { is_expected.not_to be_deletion }

    context 'when fragment starts with {-- and ends with --}' do
      let(:fragment) { '{--a fragment--}' }

      it { is_expected.to be_deletion }
    end
  end

  describe '#beginning?' do
    it { is_expected.not_to be_beginning }

    context 'when fragment is first' do
      subject(:change_fragment) do
        described_class.new(fragment, is_first: true)
      end

      it { is_expected.to be_beginning }
    end
  end

  describe '#ending?' do
    it { is_expected.not_to be_ending }

    context 'when fragment is last' do
      subject(:change_fragment) do
        described_class.new(fragment, is_last: true)
      end

      it { is_expected.to be_ending }
    end
  end

  describe '#middle?' do
    it { is_expected.to be_middle }
  end
end
