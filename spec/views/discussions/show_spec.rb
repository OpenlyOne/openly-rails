# frozen_string_literal: true

RSpec.shared_examples 'rendering discussions/show' do
  before do
    assign(:project, project)
    assign(:discussion, discussion)
  end

  it 'renders the title of the discussion' do
    render
    expect(rendered).to have_text discussion.title
  end

  it 'renders the scoped ID' do
    render
    expect(rendered).to have_text "##{discussion.scoped_id}"
  end

  it 'renders the initiator of the discussion' do
    render
    expect(rendered)
      .to have_text "#{custom_initiated_verb} by #{discussion.initiator.name}"
  end
end

RSpec.describe 'discussions/show', type: :view do
  let(:project) { discussion.project }

  context 'when @discussion is Discussions::Suggestion' do
    let(:discussion) { build_stubbed(:discussions_suggestion) }
    let(:custom_initiated_verb) { 'suggested' }
    include_examples 'rendering discussions/show'
  end

  context 'when @discussion is Discussions::Issue' do
    let(:discussion) { build_stubbed(:discussions_issue) }
    let(:custom_initiated_verb) { 'raised' }
    include_examples 'rendering discussions/show'
  end

  context 'when @discussion is Discussions::Question' do
    let(:discussion) { build_stubbed(:discussions_question) }
    let(:custom_initiated_verb) { 'asked' }
    include_examples 'rendering discussions/show'
  end
end
