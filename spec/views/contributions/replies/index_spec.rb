# frozen_string_literal: true

RSpec.describe 'contributions/replies/index', type: :view do
  let(:project)       { build_stubbed :project }
  let(:contribution)  { build_stubbed :contribution }
  let(:replies)       { [] }
  let(:reply)         { build :reply, contribution: contribution }

  before do
    assign(:project, project)
    assign(:contribution, contribution)
    assign(:replies, replies)
    assign(:reply, reply)
  end

  it 'renders the description of the contribution' do
    render
    expect(rendered).to have_text(contribution.description)
  end

  it 'does not render a form to submit a new reply' do
    render
    path = profile_project_contribution_replies_path(
      project.owner, project, contribution
    )
    expect(rendered).not_to have_css("form[action='#{path}'][method='post']")
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

  context 'when user can reply to contribution' do
    before { assign(:user_can_reply_to_contribution, true) }

    it 'renders a form to create a new reply' do
      render
      path = profile_project_contribution_replies_path(
        project.owner, project, contribution
      )
      expect(rendered).to have_css("form[action='#{path}'][method='post']")
    end

    it 'renders errors' do
      reply.errors.add(:base, 'mock error')
      render
      expect(rendered).to have_css '.validation-errors', text: 'mock error'
    end

    it 'renders a textarea for content' do
      render
      expect(rendered).to have_css 'textarea#reply_content'
    end

    it 'has a button to submit the reply' do
      render
      expect(rendered).to have_css "button[action='submit']", text: 'Reply'
    end
  end
end
