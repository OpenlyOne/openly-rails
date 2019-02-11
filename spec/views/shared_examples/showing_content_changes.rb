# frozen_string_literal: true

RSpec.shared_examples 'showing content changes' \
  do |with_link_to_side_by_side: true, link_in_new_tab: false|

  it 'does not show the content change' do
    render
    expect(rendered).not_to have_css('.fragment.addition')
    expect(rendered).not_to have_css('.fragment.deletion')
  end

  context 'when diff is modification and has content change' do
    let(:content_change) do
      VCS::Operations::ContentDiffer.new(
        new_content: 'hi',
        old_content: 'bye'
      )
    end

    before do
      allow(diff).to receive(:modification?).and_return true
      allow(diff).to receive(:content_change).and_return content_change
    end

    it 'shows the diff' do
      render
      expect(rendered).to have_css('.fragment.addition', text: 'hi')
      expect(rendered).to have_css('.fragment.deletion', text: 'bye')
    end

    if with_link_to_side_by_side
      it 'has a link to side-by-side diff' do
        render
        expect(rendered)
          .to have_link('View side-by-side', href: link_to_side_by_side)
      end
    else
      it 'does not have a link to side-by-side diff' do
        render
        expect(rendered).not_to have_link(href: link_to_side_by_side)
      end
    end

    if link_in_new_tab
      it 'opens side-by-side diff in a new tab' do
        render
        expect(rendered).to have_selector(
          "a[href='#{link_to_side_by_side}'][target='_blank']"
        )
      end
    end

    xcontext 'when all fragments are retained' do
      before do
        content_change.fragments.each do |fragment|
          allow(fragment).to receive(:retain?).and_return true
        end
      end

      it 'displays information that the text did not change' do
        render
        expect(rendered).to have_text 'Text did not change'
      end
    end
  end
end
