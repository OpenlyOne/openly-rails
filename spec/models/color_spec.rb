# frozen_string_literal: true

RSpec.describe Color, type: :model do
  describe '.schemes' do
    it 'returns an array of hashes' do
      expect(Color.schemes).to be_an Array
      Color.schemes.each do |scheme|
        expect(scheme).to be_a Hash
      end
    end

    it 'defines :base in each hash' do
      Color.schemes.each do |scheme|
        expect(scheme[:base]).not_to be_nil
      end
    end

    it 'defines :text in each hash' do
      Color.schemes.each do |scheme|
        expect(scheme[:text]).not_to be_nil
      end
    end
  end
end
