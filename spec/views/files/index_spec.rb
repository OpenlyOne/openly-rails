# frozen_string_literal: true

RSpec.describe 'files/index', type: :view do
  let(:project) { create :project }
  let(:files)   { create_list :vc_file, 5, collection: project.files }
  before do
    allow(view).to receive(:authorized_actions_for_project_file).and_return []
  end

  before do
    assign(:project, project)
    assign(:files, files)
  end

  it 'renders the name of each file' do
    render
    files.each do |file|
      expect(rendered).to have_text file.name
    end
  end

  it 'renders preview of each file' do
    render
    files.each do |file|
      expect(rendered).to have_text truncate(file.content, omission: '')
    end
  end

  it 'renders link to each file' do
    render
    files.each do |file|
      link = profile_project_file_path project.owner, project, file
      expect(rendered).to have_css("a[href='#{link}']")
    end
  end

  it 'renders the last contribution summary of each file' do
    render
    files.each do |file|
      expect(rendered).to have_text file.last_contribution.message
    end
  end

  it 'renders the last contributor of each file' do
    render
    files.each do |file|
      expect(rendered).to have_text file.last_contribution.author.name
    end
  end

  context 'when user can create file' do
    let(:new_file_path) do
      new_profile_project_file_path(project.owner, project)
    end
    before { assign(:user_can_add_file, true) }

    it 'renders link to new file path' do
      render
      expect(rendered).to have_link href: new_file_path
    end
  end
end
