# frozen_string_literal: true

RSpec.describe 'discussions/index', type: :view do
  let(:project) { create :project }
  let(:suggestions) { create_list :discussions_suggestion, 5, project: project }

  before do
    assign(:project, project)
    assign(:discussions, suggestions)
    assign(:discussion_type, 'suggestion')
  end

  it 'renders the title of each suggestion' do
    render
    suggestions.each do |suggestion|
      expect(rendered).to have_text suggestion.title
    end
  end

  it 'renders the initiator of each suggestion' do
    render
    suggestions.each do |suggestion|
      expect(rendered).to have_text suggestion.initiator.name
    end
  end

  it 'renders link to each suggestion' do
    render
    suggestions.each do |suggestion|
      link = profile_project_discussion_path(project.owner, project,
                                             'suggestions', suggestion)
      expect(rendered).to have_css("a[href='#{link}']")
    end
  end

  context 'when user can create suggestion' do
    let(:new_suggestion_path) do
      new_profile_project_discussion_path(project.owner, project, 'suggestions')
    end
    before { assign(:user_can_add_discussion, true) }

    it 'renders link to new suggestion path' do
      render
      expect(rendered).to have_link href: new_suggestion_path
    end
  end
end
