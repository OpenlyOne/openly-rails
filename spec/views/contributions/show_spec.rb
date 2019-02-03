# frozen_string_literal: true

RSpec.describe 'contributions/show', type: :view do
  let(:project)       { build_stubbed :project }
  let(:contribution)  { build_stubbed :contribution }

  before do
    assign(:project, project)
    assign(:contribution, contribution)
  end

  it 'renders the description of the contribution' do
    render
    expect(rendered).to have_text(contribution.description)
  end
end
