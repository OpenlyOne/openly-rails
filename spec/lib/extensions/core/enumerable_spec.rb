# frozen_string_literal: true

RSpec.describe Enumerable, type: :module do
  describe '#split_with_delimiter' do
    subject(:split) { enumerable.split_with_delimiter { |i| i == 3 } }

    let(:enumerable) { [1, 2, 3, 4, 5] }

    it 'splits the enumerable and keeps the delimiter' do
      expect(split.to_a).to eq [[1, 2], [3], [4, 5]]
    end

    context 'when delimiter matches multiple times' do
      subject(:split) { enumerable.split_with_delimiter(&:even?) }

      it 'splits the enumerable multiple times' do
        expect(split.to_a).to eq [[1], [2], [3], [4], [5]]
      end
    end
  end
end
