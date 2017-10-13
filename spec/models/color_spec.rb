# frozen_string_literal: true

RSpec.describe Color, type: :model do
  it 'has 9 modifiers for shades' do
    expect(Color::SHADES.count).to eq 10
  end

  it 'has 4 modifiers for accents' do
    expect(Color::ACCENTS.count).to eq 4
  end

  it 'has font color breakpoints for 21 colors' do
    expect(Color::FONT_COLOR_BREAK_POINTS.count).to eq 21
  end

  describe '.font_color_for' do
    subject(:method) { Color.font_color_for("#{color} #{modifier}") }

    context 'when color is red' do
      let(:color) { 'red' }
      context 'when modifier is darken-1' do
        let(:modifier) { 'darken-1' }
        it { is_expected.to eq 'black-text' }
      end
      context 'when modifier is darken-2' do
        let(:modifier) { 'darken-2' }
        it { is_expected.to eq 'white-text' }
      end
      context 'when modifier is accent-3' do
        let(:modifier) { 'accent-3' }
        it { is_expected.to eq 'black-text' }
      end
      context 'when modifier is accent-4' do
        let(:modifier) { 'accent-4' }
        it { is_expected.to eq 'white-text' }
      end
    end

    context 'when color is indigo' do
      let(:color) { 'indigo' }
      context 'when modifier is darken-1' do
        let(:modifier) { 'lighten-2' }
        it { is_expected.to eq 'black-text' }
      end
      context 'when modifier is darken-2' do
        let(:modifier) { 'lighten-1' }
        it { is_expected.to eq 'white-text' }
      end
      context 'when modifier is accent-1' do
        let(:modifier) { 'accent-1' }
        it { is_expected.to eq 'black-text' }
      end
      context 'when modifier is accent-2' do
        let(:modifier) { 'accent-2' }
        it { is_expected.to eq 'white-text' }
      end
    end

    context 'when color is black' do
      let(:color) { 'black' }
      let(:modifier) { 'base' }
      it { is_expected.to eq 'white-text' }
    end

    context 'when color is white' do
      let(:color) { 'white' }
      let(:modifier) { 'base' }
      it { is_expected.to eq 'black-text' }
    end
  end

  describe '.options' do
    it 'returns a one-dimensional array' do
      Color.options.each do |option|
        expect(option).to be_a String
      end
    end

    it 'returns 256 options' do
      expect(Color.options.count).to eq 256
    end
  end

  describe '.schemes' do
    it 'returns an array of strings' do
      expect(Color.schemes).to be_an Array
      Color.schemes.each do |scheme|
        expect(scheme).to be_a String
      end
    end

    it 'returns valid color options' do
      Color.schemes.each do |scheme|
        expect(Color.options).to include scheme
      end
    end
  end
end
