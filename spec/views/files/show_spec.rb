# frozen_string_literal: true

RSpec.describe 'files/show', type: :view do
  let(:project) { create(:project) }
  let(:file)    { create(:vc_file, collection: project.files) }

  before do
    assign(:project, project)
    assign(:file, file)
  end

  it 'renders the name of the file' do
    render
    expect(rendered).to have_text file.name
  end

  it 'renders the content of the file' do
    render
    expect(rendered).to have_text file.content
  end

  context 'when file contents are empty' do
    before { allow(file).to receive(:content).and_return('') }

    it 'tells the user that the file is empty' do
      render
      expect(rendered).to have_css 'em', text: 'This file is empty'
    end
  end
end
