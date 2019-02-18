# frozen_string_literal: true

RSpec.describe 'contributions/show', type: :view do
  let(:project)       { build_stubbed :project }
  let(:contribution)  { build_stubbed :contribution }
  let(:replies)       { [] }

  before do
    assign(:project, project)
    assign(:contribution, contribution)
    assign(:replies, replies)
  end

  it 'renders the description of the contribution' do
    render
    expect(rendered).to have_text(contribution.description)
  end

  context 'when contribution has replies' do
    let(:replies) { build_stubbed_list :reply, 3, contribution: contribution }

    it 'renders each reply author' do
      render
      replies.map(&:author).each do |author|
        expect(rendered).to have_link author.name, href: profile_path(author)
      end
    end

    it 'renders each reply content' do
      render
      replies.map(&:content).each do |content|
        expect(rendered).to have_text(content)
      end
    end
  end
end
