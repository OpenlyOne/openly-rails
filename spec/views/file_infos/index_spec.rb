# frozen_string_literal: true

RSpec.describe 'file_infos/index', type: :view do
  let(:project)       { build_stubbed :project }
  let(:file)          { build :file }
  let(:file_versions) { [] }

  before do
    assign(:project, project)
    assign(:file, file)
    assign(:file_versions, file_versions)
  end

  it 'renders the file icon' do
    render
    icon = view.icon_for_file(file)
    expect(rendered).to have_css "h2 img[src='#{view.asset_path(icon)}']"
  end

  it 'renders the file name' do
    render
    expect(rendered).to have_css 'h2', text: file.name
  end

  it 'has a link to the file on Google Drive' do
    render
    expect(rendered).to have_link 'Open in Drive',
                                  href: view.external_link_for_file(file)
  end

  it 'has a link to the parent folder' do
    render
    link = profile_project_folder_path(project.owner, project, file.parent_id)
    expect(rendered).to have_link 'Open Parent Folder', href: link
  end

  xcontext 'when file is and has been deleted' do
    it 'does not have a link to the file on Google Drive' do
    end

    it 'does not have a link to the parent folder' do
    end
  end
end
