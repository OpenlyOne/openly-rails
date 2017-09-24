# frozen_string_literal: true

RSpec.shared_examples 'rendering discussions/index' do
  before do
    assign(:project, project)
    assign(:discussions, discussions)
    assign(:discussion_type, discussion_type)
  end

  it 'renders the type of discussion as title' do
    render
    expect(rendered).to have_css 'h2', text: discussion_type.titleize
  end

  it 'renders the title of each discussion' do
    render
    discussions.each do |discussion|
      expect(rendered).to have_text discussion.title
    end
  end

  it 'renders the initiator of each discussion' do
    render
    discussions.each do |discussion|
      expect(rendered).to have_text discussion.initiator.name
    end
  end

  it 'renders link to each discussion' do
    render
    discussions.each do |discussion|
      link = profile_project_discussion_path(project.owner, project,
                                             discussion_type.pluralize,
                                             discussion)
      expect(rendered).to have_css("a[href='#{link}']")
    end
  end

  context 'when user can create discussion' do
    let(:new_discussion_path) do
      new_profile_project_discussion_path(project.owner, project,
                                          discussion_type.pluralize)
    end
    before { assign(:user_can_add_discussion, true) }

    it 'renders link to new discussion path' do
      render
      expect(rendered).to have_link href: new_discussion_path
    end
  end
end

RSpec.describe 'discussions/index', type: :view do
  let(:project) { create :project }
  let(:discussion_type) { discussions.first.type_to_url_segment.singularize }

  context 'when @discussions is Discussions::Suggestion' do
    let(:discussions) do
      create_list(:discussions_suggestion, 5, project: project)
    end
    include_examples 'rendering discussions/index'
  end

  context 'when @discussions is Discussions::Issue' do
    let(:discussions) do
      create_list(:discussions_issue, 5, project: project)
    end
    include_examples 'rendering discussions/index'
  end
end
