# frozen_string_literal: true

RSpec.describe 'contributions/reviews/show', type: :view do
  let(:project)       { build_stubbed :project, :with_repository }
  let(:repository)    { project.repository }
  let(:master_branch) { build_stubbed :vcs_branch, repository: repository }
  let(:revision)      { build_stubbed :vcs_commit, branch: contribution.branch }
  let(:contribution)  { build_stubbed :contribution, project: project }
  let(:file_diffs)    { [] }

  before do
    allow(contribution).to receive(:revision).and_return revision
    allow(revision).to receive(:file_diffs).and_return(file_diffs)
  end

  before do
    assign(:project, project)
    assign(:master_branch, master_branch)
    assign(:contribution, contribution)
    controller.request.path_parameters[:profile_handle] = project.owner.to_param
    controller.request.path_parameters[:project_slug] = project.to_param
  end

  it 'lets the user know that there are no changes to review' do
    render
    expect(rendered).to have_text 'No changes suggested.'
  end

  it 'does not have a form to accept changes' do
    render
    path = profile_project_contribution_acceptance_path(
      project.owner, project, contribution
    )
    expect(rendered).not_to have_css(
      "form[action='#{path}'][method='post']", text: 'Accept Changes'
    )
  end

  context 'when user has permission to accept contribution' do
    before { assign(:user_can_accept_contribution, true) }

    it 'renders a button to accept the contribution' do
      render
      path = profile_project_contribution_acceptance_path(
        project.owner, project, contribution
      )
      expect(rendered).to have_css(
        "form[action='#{path}'][method='post']", text: 'Accept Changes'
      )
    end

    it 'renders errors' do
      # add contribution error
      contribution.errors.add(:base, 'mock contribution error')
      # add revision error
      revision.errors.add(:base, 'mock revision error')
      render
      expect(rendered).to have_css '.validation-errors',
                                   text: 'mock revision error'
      expect(rendered).to have_css '.validation-errors',
                                   text: 'mock contribution error'
    end

    it 'shows a warning about uncaptured changes being lost' do
      render
      expect(rendered).to have_text 'lose any uncaptured changes'
    end

    context 'when contribution has already been accepted' do
      before do
        allow(contribution).to receive(:open?).and_return false
      end

      it 'does not have a form to accept changes' do
        render
        path = profile_project_contribution_acceptance_path(
          project.owner, project, contribution
        )
        expect(rendered).not_to have_css(
          "form[action='#{path}'][method='post']", text: 'Accept Changes'
        )
      end

      it 'still displays form errors' do
        # add contribution error
        contribution.errors.add(:base, 'mock contribution error')
        # add revision error
        revision.errors.add(:base, 'mock revision error')
        render
        expect(rendered).to have_css '.validation-errors',
                                     text: 'mock revision error'
        expect(rendered).to have_css '.validation-errors',
                                     text: 'mock contribution error'
      end
    end
  end

  context 'when file diffs exist' do
    let(:file_diffs) do
      versions.map do |version|
        VCS::FileDiff.new(new_version: version, first_three_ancestors: [])
      end
    end
    let(:versions) do
      build_stubbed_list(:vcs_version, 3, :with_backup)
    end

    before do
      root = instance_double VCS::FileInBranch
      allow(master_branch).to receive(:root).and_return root
      allow(root).to receive(:provider).and_return Providers::GoogleDrive
    end

    it 'it lists files as added' do
      render
      file_diffs.each do |diff|
        expect(rendered)
          .to have_css('.file.addition', text: "#{diff.name} to be added")
      end
    end

    it 'renders a link to each file backup' do
      render
      file_diffs.each do |diff|
        link = diff.current_version.backup.link_to_remote
        expect(rendered).to have_link(text: diff.name, href: link)
      end
    end

    it 'renders a link to each file info page' do
      render
      file_diffs.each do |diff|
        link = profile_project_contribution_file_infos_path(
          project.owner, project, contribution, diff.hashed_file_id
        )
        expect(rendered).to have_link(text: 'More', href: link)
      end
    end

    it 'marks all links as local links' do
      render
      expect(rendered).not_to have_css("a[target='_blank']", text: 'More')
      expect(rendered).to have_css("a:not([target='_blank'])", text: 'More')
    end

    context 'when user can accept changes' do
      before { assign(:user_can_accept_contribution, true) }

      it 'marks all links as remote links' do
        render
        expect(rendered).to have_css("a[target='_blank']")
        expect(rendered).not_to have_css("a:not([target='_blank'])")
      end
    end

    context 'when change is addition' do
      before { allow(file_diffs.first).to receive(:addition?).and_return true }

      it do
        render
        expect(rendered).to have_text 'to be added to'
      end
    end

    context 'when change is modification' do
      before do
        allow(file_diffs.first).to receive(:modification?).and_return true
      end

      it do
        render
        expect(rendered).to have_text 'to be modified in'
      end
    end

    context 'when change is rename' do
      before { allow(file_diffs.first).to receive(:rename?).and_return true }

      it do
        render
        expect(rendered).to have_text 'to be renamed from'
      end
    end

    context 'when change is movement' do
      before { allow(file_diffs.first).to receive(:movement?).and_return true }

      it do
        render
        expect(rendered).to have_text 'to be moved to'
      end
    end

    context 'when change is deletion' do
      before { allow(file_diffs.first).to receive(:deletion?).and_return true }

      it do
        render
        expect(rendered).to have_text 'to be deleted from'
      end
    end

    context 'when diff is modification and has content change' do
      let(:change) { revision.file_changes.first }
      let(:content_change) do
        VCS::Operations::ContentDiffer.new(
          new_content: 'hi',
          old_content: 'bye'
        )
      end
      let(:link_to_side_by_side) do
        profile_project_contribution_file_change_path(
          project.owner, project, contribution, change.hashed_file_id
        )
      end

      before do
        allow(change).to receive(:modification?).and_return true
        allow(change).to receive(:content_change).and_return content_change
      end

      it 'shows the diff' do
        render
        expect(rendered).to have_css('.fragment.addition', text: 'hi')
        expect(rendered).to have_css('.fragment.deletion', text: 'bye')
      end

      it 'has a link to side-by-side diff' do
        render
        expect(rendered)
          .to have_link('View side-by-side', href: link_to_side_by_side)
      end

      it 'opens side-by-side diff in the same tab' do
        render
        expect(rendered).to have_selector(
          "a[href='#{link_to_side_by_side}']:not([target='_blank'])"
        )
      end

      context 'when user can accept changes' do
        before { assign(:user_can_accept_contribution, true) }

        it 'opens side-by-side diff in a new tab' do
          render
          expect(rendered).to have_selector(
            "a[href='#{link_to_side_by_side}'][target='_blank']"
          )
        end
      end
    end
  end
end
