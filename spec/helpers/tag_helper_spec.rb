# frozen_string_literal: true

RSpec.describe TagHelper, type: :helper do
  describe '#tag_case(tag)' do
    subject(:method)  { helper.tag_case(tag) }
    let(:tag)         { 'my tag' }

    it 'upcases the first letter of every word' do
      is_expected.to eq 'My Tag'
    end

    context 'when tag contains uppercase characters' do
      let(:tag) { 'my AweSOME tag' }

      it 'leaves those characters unaffected' do
        is_expected.to eq 'My AweSOME Tag'
      end
    end
  end
end
