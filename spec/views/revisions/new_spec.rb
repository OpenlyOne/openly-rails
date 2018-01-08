# frozen_string_literal: true

RSpec.describe 'revisions/new', type: :view do
  let(:project)   { create(:project) }
  let(:revision)  { project.repository.build_revision }

  before do
    assign(:project, project)
    assign(:revision, revision)
    controller.request.path_parameters[:profile_handle] = project.owner.to_param
    controller.request.path_parameters[:project_slug] = project.to_param
  end

  it 'renders a form with profile_project_revision_path action' do
    render
    expect(rendered).to have_css(
      'form'\
      "[action='#{profile_project_revisions_path(project.owner, project)}']"\
      "[method='post']"
    )
  end

  it 'renders errors' do
    revision.errors.add(:base, 'mock error')
    render
    expect(rendered).to have_css '.validation-errors', text: 'mock error'
  end

  it 'has a hidden field for revision tree' do
    render
    expect(rendered).to have_css(
      "input#revision_tree_id[value='#{revision.tree_id}']",
      visible: false
    )
  end

  it 'has a text area for revision summary' do
    render
    expect(rendered).to have_css 'textarea#revision_summary'
  end

  it 'has a button to commit changes' do
    render
    expect(rendered)
      .to have_css "button[action='submit']", text: 'Commit Changes'
  end

  context 'when last revision id does not match actual last revision id' do
    before { revision.instance_variable_set :@last_revision_id, 'abc' }
    before { revision.valid? }

    it 'does not list the last_revision_id error' do
      render
      revision.errors.full_messages_for(:last_revision_id).each do |error_text|
        expect(rendered).not_to have_text(error_text)
      end
    end

    it 'explains to the user that another commit has occured' do
      render
      expect(rendered).to have_text(
        'Someone else has committed changes to this project since you ' \
        'started reviewing changes.'
      )
    end

    it 'renders a link to start over' do
      render
      expect(rendered).to have_link(
        'Click here to start over',
        href: new_profile_project_revision_path(project.owner, project)
      )
    end
  end
end
