# frozen_string_literal: true

require 'controllers/shared_examples/a_redirect_with_success.rb'
require 'controllers/shared_examples/an_authenticated_action.rb'
require 'controllers/shared_examples/an_authorized_action.rb'
require 'controllers/shared_examples/authorizing_project_access.rb'
require 'controllers/shared_examples/raise_404_if_non_existent.rb'
require 'controllers/shared_examples/setting_project.rb'
require 'controllers/shared_examples/successfully_rendering_view.rb'

RSpec.describe Contributions::AcceptancesController, type: :controller do
  let!(:project)      { create :project, :setup_complete, :skip_archive_setup }
  let(:master_branch) { project.master_branch }
  let!(:contribution) { create :contribution, project: project }
  let!(:revision) do
    create :vcs_commit, branch: contribution.branch, author: author,
                        parent: project.revisions.last
  end
  let(:default_params) do
    {
      profile_handle:   project.owner.to_param,
      project_slug:     project.slug,
      contribution_id:  contribution.id,
      contribution: {
        revision_id: revision.id
      }
    }
  end
  let(:current_account) { project.owner.account }
  let(:author)          { current_account.user }
  before                { sign_in current_account }

  describe 'POST #create' do
    let(:params)          { default_params }
    let(:run_request)     { post :create, params: params }

    it_should_behave_like 'an authenticated action'
    it_should_behave_like 'raise 404 if non-existent', Project
    it_should_behave_like 'raise 404 if non-existent', Contribution
    it_should_behave_like 'an authorized action' do
      let(:redirect_location) do
        profile_project_contribution_review_path(
          project.owner, project, contribution
        )
      end
      let(:unauthorized_message) do
        'You are not authorized to accept this contribution.'
      end
    end

    it_should_behave_like 'a redirect with success' do
      let(:redirect_location) do
        profile_project_root_folder_path(project.owner, project)
      end
      let(:notice) do
        'Contribution successfully accepted. ' \
        'Suggested changes are being applied...'
      end
    end
    it_should_behave_like 'authorizing project access'

    it 'accepts the contribution' do
      expect_any_instance_of(Contribution)
        .to receive(:accept)
        .with(
          hash_including(revision: revision, acceptor: current_account.user)
        ).and_return true
      run_request
    end

    context 'when acception fails' do
      before do
        create(:vcs_file_in_branch, :root, branch: master_branch)
        allow_any_instance_of(Contribution)
          .to receive(:accept)
          .and_wrap_original do |method, revision:, acceptor:|
          # manually assign revision to contribution
          method.receiver.revision = revision
          method.receiver.acceptor = acceptor
          false
        end
      end

      it_should_behave_like 'successfully rendering view'
    end
  end
end
