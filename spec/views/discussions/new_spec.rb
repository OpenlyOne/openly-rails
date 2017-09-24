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

  it 'has a button to create the discussion' do
    render
    expect(rendered).to have_css "button[action='submit']", text: 'Create'
  end
end

RSpec.describe 'discussions/new', type: :view do
  let(:project) { discussion.project }

  context 'when @discussion is Discussions::Suggestion' do
    let(:discussion) { build(:discussions_suggestion) }
    include_examples 'rendering discussions/new'
  end

  context 'when @discussion is Discussions::Issue' do
    let(:discussion) { build(:discussions_issue) }
    include_examples 'rendering discussions/new'
  end
end
