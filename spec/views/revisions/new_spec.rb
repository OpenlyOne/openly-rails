# frozen_string_literal: true

RSpec.describe 'revisions/new', type: :view do
  let(:project)                 { create(:project) }
  let(:revision)                { project.repository.build_revision }
  let(:file_diffs)              { [] }
  let(:revision_diff)           { instance_double VersionControl::RevisionDiff }
  let(:ancestors_of_file_diffs) { {} }

  before do
    assign(:project, project)
    assign(:revision, revision)
    assign(:file_diffs, file_diffs)
    assign(:ancestors_of_file_diffs, ancestors_of_file_diffs)
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

  it 'has a text field for revision titile' do
    render
    expect(rendered).to have_css 'input#revision_title'
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

  it 'lets the user know that there are no changes to review' do
    render
    expect(rendered).to have_text 'There are no changes to review.'
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

  context 'when file diffs exist' do
    let(:file_diffs) do
      [added_file_diff, modified_file_diff, moved_file_diff,
       modified_and_moved_file_diff, deleted_file_diff]
    end
    let(:revision_diff) { instance_double VersionControl::RevisionDiff }
    let(:added_file_diff) do
      VersionControl::FileDiff.new(revision_diff, build(:file), nil)
    end
    let(:modified_file_diff) do
      VersionControl::FileDiff.new(
        revision_diff,
        build(:file, parent_id: 'same', modified_time: Time.new(2018, 1, 1)),
        build(:file, parent_id: 'same', modified_time: Time.new(2017, 12, 31))
      )
    end
    let(:moved_file_diff) do
      VersionControl::FileDiff.new(
        revision_diff,
        build(:file, parent_id: 'new', modified_time: Time.new(2018, 1, 1)),
        build(:file, parent_id: 'old', modified_time: Time.new(2018, 1, 1))
      )
    end
    let(:modified_and_moved_file_diff) do
      VersionControl::FileDiff.new(
        revision_diff,
        build(:file, parent_id: 'new', modified_time: Time.new(2018, 1, 5)),
        build(:file, parent_id: 'old', modified_time: Time.new(2013, 8, 18))
      )
    end
    let(:deleted_file_diff) do
      VersionControl::FileDiff.new(revision_diff, nil, build(:file))
    end
    let(:ancestors_of_file_diffs) do
      file_diffs.index_by(&:id).transform_values! do |_|
        [build(:file, name: 'ancestor'), build(:file, name: 'root')]
      end
    end

    it 'lists diff for added file with path' do
      render
      expect(rendered).to have_css(
        '.file.added',
        text: "#{added_file_diff.name} added to Home > ancestor"
      )
    end

    it 'lists diff for modified file without path' do
      render
      expect(rendered).to have_css(
        '.file.modified',
        text: "#{modified_file_diff.name} modified"
      )
      expect(rendered).not_to have_css '.file.modified', text: 'Home > ancestor'
    end

    it 'lists diff for moved file with path' do
      render
      expect(rendered).to have_css(
        '.file.moved',
        text: "#{moved_file_diff.name} moved to Home > ancestor"
      )
    end

    it 'lists diff for deleted file with path' do
      render
      expect(rendered).to have_css(
        '.file.deleted',
        text: "#{deleted_file_diff.name} deleted from Home > ancestor"
      )
    end

    it 'lists two  diffs for modified and moved file' do
      render
      expect(rendered).to have_css(
        '.file.modified',
        text: "#{modified_and_moved_file_diff.name} modified"
      )
      expect(rendered).to have_css(
        '.file.moved',
        text: "#{modified_and_moved_file_diff.name} moved to Home > ancestor"
      )
    end
  end
end
