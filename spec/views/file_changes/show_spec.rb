# frozen_string_literal: true

RSpec.describe 'file_changes/show', type: :view do
  let(:file_diff) { instance_double VCS::FileDiff }
  let(:differ) do
    VCS::Operations::ContentDiffer.new(
      new_content: new_content, old_content: old_content
    )
  end
  let(:new_content) do
    <<~TEXT
      Hi,

      my name is Finn.

      How are you? :)
    TEXT
  end
  let(:old_content) do
    <<~TEXT
      Hello,

      my middle name is Lucy. How are you?
    TEXT
  end

  before do
    assign(:file_diff, file_diff)
    allow(file_diff).to receive(:content_change).and_return differ
  end

  it 'has headers: Before <-> Now' do
    render
    expect(rendered).to have_css('.header-row', text: 'BeforeNow')
  end

  it 'renders correct content on the old/left side' do
    render
    left_side =
      Nokogiri::HTML(
        rendered.gsub(%r{<br.?/?>}, "\n")
      ).css('.row .old').map(&:text)

    expect(left_side).to eq(
      ["Hello,\n\n", "my middle name is Lucy. How are you?\n"]
    )
  end

  it 'renders correct content on the new/right side' do
    render
    left_side =
      Nokogiri::HTML(
        rendered.gsub(%r{<br.?/?>}, "\n")
      ).css('.row .new').map(&:text)

    expect(left_side).to eq(
      ["Hi,\n\n", "my name is Finn.\n\nHow are you? :)\n"]
    )
  end

  context 'when revision is present' do
    before do
      assign(:revision, instance_double(VCS::Commit))
    end

    it 'has headers: Before <-> After' do
      render
      expect(rendered).to have_css('.header-row', text: 'BeforeAfter')
    end
  end
end
