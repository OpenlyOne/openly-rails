# frozen_string_literal: true

RSpec.describe 'files/show', type: :view do
  let(:project) { create(:project) }
  let(:file)    { create(:vc_file, collection: project.files) }
  before do
    allow(view).to receive(:authorized_actions_for_project_file).and_return []
  end

  before do
    assign(:project, project)
    assign(:file, file)
  end

  it 'renders the name of the file' do
    render
    expect(rendered).to have_text file.name
  end

  it 'renders the last contribution summary' do
    render
    expect(rendered).to have_text file.last_contribution.message
  end

  it 'renders the last contributor' do
    render
    expect(rendered).to have_text file.last_contribution.author.name
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

  context 'when user can perform authorized file actions' do
    let(:authorized_actions) do
      [{ name: 'Action1', link: 'href1' },
       { name: 'Action2', link: 'href2' }]
    end
    before do
      allow(view).to receive(:authorized_actions_for_project_file)
        .and_return authorized_actions
    end

    it 'renders authorized actions' do
      render
      authorized_actions.each do |action|
        expect(rendered).to have_link href: action[:link]
      end
    end
  end
end
