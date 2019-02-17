# frozen_string_literal: true

RSpec.describe 'contributions/_head', type: :view do
  let(:contribution) { build_stubbed(:contribution) }
  let(:project)      { build_stubbed(:project) }
  let(:root)         { nil }

  before do
    allow(contribution).to receive_message_chain(:files, :root).and_return root
    allow(root).to receive(:link_to_remote).and_return link_to_remote if root
  end

  before do
    without_partial_double_verification do
      allow(view).to receive(:project) { project }
      allow(view).to receive(:contribution) { contribution }
      allow(view).to receive(:active_tab) { nil }
    end
  end

  it 'renders the title of the contribution' do
    render
    expect(rendered).to have_text contribution.title
  end

  it 'renders the creator of the contribution' do
    render
    expect(rendered).to have_link(
      contribution.creator.name,
      href: profile_path(contribution.creator)
    )
  end

  it 'renders a link to the description' do
    render
    expect(rendered).to have_link(
      'Description',
      href: profile_project_contribution_path(
        project.owner, project, contribution
      )
    )
  end

  it 'renders a link to the files' do
    render
    expect(rendered).to have_link(
      'Files',
      href: profile_project_contribution_root_folder_path(
        project.owner, project, contribution
      )
    )
  end

  it 'renders a link to review the changes' do
    render
    expect(rendered).to have_link(
      'Review',
      href: profile_project_contribution_review_path(
        project.owner, project, contribution
      )
    )
  end

  it 'does not render a link to open contribution in Google Drive' do
    render
    expect(rendered).not_to have_link('Open in Drive')
  end

  it 'does not render that the contribution is accepted' do
    render
    expect(rendered).not_to have_text 'accepted'
  end

  context 'when the contribution has been accepted' do
    before { allow(contribution).to receive(:accepted?).and_return true }

    it 'renders that it was accepted' do
      render
      expect(rendered).to have_text 'accepted'
    end
  end

  context 'when link_to_remote is present' do
    let(:root) { build_stubbed :vcs_file_in_branch, :root }
    let(:link_to_remote) { 'link-to-remote' }

    it 'renders a link to open the contribution root folder in Google Drive' do
      render
      expect(rendered).to have_link(
        'Open in Drive', href: 'link-to-remote'
      )
    end
  end
end
