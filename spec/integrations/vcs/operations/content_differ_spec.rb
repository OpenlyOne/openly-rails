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
        '{--Hi,--}{++Hello,++} my {--last --}name is {--Long.--}{++Lara.++}'
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

    context 'when inserting line breaks' do
      let(:new_content) { "Hello,\n\nmy name is Lara." }
      let(:old_content) { 'Hello, my name is Lara.' }

      it 'shows two line breaks as added and one space as removed' do
        is_expected.to eq("Hello,{-- --}{++\n\n++}my name is Lara.")
      end
    end

    context 'when inserting spaces' do
      let(:new_content) { 'Hello, my name is   Lara.' }
      let(:old_content) { 'Hello, my name is Lara.' }

      it 'shows two line breaks as added and one space as removed' do
        is_expected.to eq(
          'Hello, my name is {++  ++}Lara.'
        )
      end
    end
  end

  describe '#fragments' do
    subject(:fragments) { differ.fragments }

    it 'fragments the change' do
      expect(fragments.length).to eq 7
      expect(fragments.map { |frag| [frag.type, frag.content] }).to eq(
        [
          [:deletion, 'Hi,'],
          [:addition, 'Hello,'],
          [:middle,   ' my '],
          [:deletion, 'last '],
          [:middle,   'name is '],
          [:deletion, 'Long.'],
          [:addition, 'Lara.']
        ]
      )
    end

    context 'when making changes to consecutive words' do
      let(:new_content) { 'This is super incredibly awesome' }
      let(:old_content) { 'This is pretty wonderfully awesome' }

      it 'keeps related changes together' do
        expect(fragments.map { |frag| [frag.type, frag.content] }).to eq(
          [
            [:beginning,  'This is '],
            [:deletion,   'pretty wonderfully'],
            [:addition,   'super incredibly'],
            [:ending,     ' awesome']
          ]
        )
      end
    end
  end

  describe '#fragments_by_paragraph' do
    subject(:fragments_by_paragraph) { differ.fragments_by_paragraph }

    let(:new_content) { "This is a\n\ngreat opportunity." }
    let(:old_content) { "This\n\nwas is fantastic" }

    it 'returns paragraphs' do
      expect(fragments_by_paragraph.map(&:content)).to eq(
        ['This', "\n\n", 'was', ' is ', 'fantastic', 'a', "\n\n",
         'great opportunity.']
      )
    end
  end
end
