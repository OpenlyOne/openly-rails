# frozen_string_literal: true

RSpec.describe 'discussions/show', type: :view do
  let(:suggestion) { create(:discussions_suggestion) }

  before do
    assign(:project, suggestion.project)
    assign(:discussion, suggestion)
  end

  it 'renders the title of the discussion' do
    render
    expect(rendered).to have_text suggestion.title
  end

  it 'renders the initiator of the discussion' do
    render
    expect(rendered).to have_text suggestion.initiator.name
  end
end
