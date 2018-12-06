# frozen_string_literal: true

RSpec.describe VCS::Operations::ContentDiffer, type: :model do
  subject(:differ) do
    described_class.new(new_content: new_content, old_content: old_content)
  end

  let(:new_content) { 'Hello, my name is Lara.' }
  let(:old_content) { 'Hi, my last name is Long.' }

  describe '.change(new_content, old_content)' do
    subject(:change) { described_class.change(new_content, old_content) }

    it do
      is_expected.to eq(
        '{--Hi,--}{++Hello,++} my {--last--} name is {--Long.--} {++Lara.++}'
      )
    end

    context 'when text contains delimiter characters' do
      let(:new_content) { '{++test++}' }
      let(:old_content) { '{++test++}' }

      it 'encodes them' do
        is_expected.not_to include('{++')
        is_expected.not_to include('++}')
      end
    end
  end

  describe '#fragments' do
    subject(:fragments) { differ.fragments }

    it 'fragments the change' do
      expect(fragments.length).to eq 7
      expect(fragments.map { |frag| [frag.type, frag.content]}).to eq(
        [
          [:deletion, 'Hi,'],
          [:addition, 'Hello,'],
          [:middle,   ' my '],
          [:deletion, 'last'],
          [:middle,   ' name is '],
          [:deletion, 'Long.'],
          [:addition, 'Lara.']
        ]
      )
    end
  end
end
