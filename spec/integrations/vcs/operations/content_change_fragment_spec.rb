# frozen_string_literal: true

RSpec.describe VCS::Operations::ContentChangeFragment, type: :model do
  describe '.klass_for_fragment(raw_content)' do
    subject(:klass) { described_class.klass_for_fragment(raw_content) }

    let(:raw_content) { 'some content' }

    it { is_expected.to be described_class::Retain }

    context 'when raw content starts with {++' do
      let(:raw_content) { '{++add me++}' }

      it { is_expected.to be described_class::Addition }
    end

    context 'when raw content starts with {--' do
      let(:raw_content) { '{--deletion--}' }

      it { is_expected.to be described_class::Deletion }
    end
  end

  describe '.parse_raw_content(raw_content)' do
    subject(:content) { described_class.parse_raw_content(raw_content) }

    context 'when raw content has delimiters' do
      let(:raw_content) { '{++A COOL fragment++}' }

      it { is_expected.to eq 'A COOL fragment' }
    end

    context 'when raw content has escaped content' do
      let(:raw_content) { 'HELL\\+LO\\-\\-OK' }

      it { is_expected.to eq 'HELL+LO--OK' }
    end

    context 'when raw content is escaped and delimited' do
      let(:raw_content) { '{--HEY\\+\\-OK--}' }

      it { is_expected.to eq 'HEY+-OK' }
    end
  end

  describe 'Addition' do
    subject(:addition) { described_class::Addition.new(content: 'abc') }

    it { is_expected.to be_addition }
    it { expect(addition.type).to eq :addition }
  end

  describe 'Deletion' do
    subject(:deletion) { described_class::Deletion.new(content: 'abc') }

    it { is_expected.to be_deletion }
    it { expect(deletion.type).to eq :deletion }
  end

  describe 'Retain' do
    subject(:retain) { described_class::Retain.new(content: 'abc') }

    it { is_expected.to be_retain }
    it { is_expected.to be_middle }
    it { expect(retain.type).to eq :middle }

    context 'when fragment is first' do
      subject(:retain) do
        described_class::Retain.new(content: 'abc', is_first: true)
      end

      it { is_expected.to be_beginning }
      it { expect(retain.type).to eq :beginning }
    end

    context 'when fragment is last' do
      subject(:retain) do
        described_class::Retain.new(content: 'abc', is_last: true)
      end

      it { is_expected.to be_ending }
      it { expect(retain.type).to eq :ending }
    end

    describe 'truncated_content(num_chars)' do
      subject(:truncated_content) { retain.truncated_content(num_chars) }

      let(:retain)        { described_class::Retain.new(content: content) }
      let(:num_chars)     { 3 }
      let(:content)       { 'abcdefghijklmnopqrstuvwxyz' }
      let(:is_beginning)  { false }
      let(:is_ending)     { false }
      let(:is_middle)     { false }

      before do
        allow(retain).to receive(:beginning?).and_return is_beginning
        allow(retain).to receive(:ending?).and_return is_ending
        allow(retain).to receive(:middle?).and_return is_middle
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
  end
end
