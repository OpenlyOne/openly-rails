# frozen_string_literal: true

RSpec.shared_examples 'rendering discussions/new' do
  before do
    assign(:project, project)
    assign(:discussion, discussion)
  end

  it 'renders a form with profile_project_discussions_path action' do
    create_path =
      profile_project_discussions_path(project.owner, project,
                                       discussion.type_to_url_segment)
    render
    expect(rendered).to have_css(
      'form'\
      "[action='#{create_path}']"\
      "[method='post']"
    )
  end

  it 'renders errors' do
    discussion.errors.add(:base, 'mock error')
    render
    expect(rendered).to have_css '.validation-errors', text: 'mock error'
  end

  it 'has an input field for title' do
    render
    expect(rendered).to have_css(
      "input#discussions_#{discussion.type_to_url_segment.singularize}_title"
    )
  end

  it 'renders the initiator' do
    render
    expect(rendered)
      .to have_text "#{custom_initiated_verb} by #{discussion.initiator.name}"
  end

  it 'has a button to create the discussion' do
    render
    expect(rendered).to have_css "button[action='submit']", text: 'Create'
  end
end

RSpec.describe 'discussions/new', type: :view do
  let(:project) { discussion.project }

  context 'when @discussion is Discussions::Suggestion' do
    let(:discussion) { build(:discussions_suggestion) }
    let(:custom_initiated_verb) { 'suggested' }
    include_examples 'rendering discussions/new'
  end

  context 'when @discussion is Discussions::Issue' do
    let(:discussion) { build(:discussions_issue) }
    let(:custom_initiated_verb) { 'raised' }
    include_examples 'rendering discussions/new'
  end

  context 'when @discussion is Discussions::Question' do
    let(:discussion) { build(:discussions_question) }
    let(:custom_initiated_verb) { 'asked' }
    include_examples 'rendering discussions/new'
  end
end
