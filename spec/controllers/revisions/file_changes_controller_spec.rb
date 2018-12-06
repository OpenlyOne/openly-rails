# frozen_string_literal: true

require 'controllers/shared_examples/authorizing_project_access.rb'
require 'controllers/shared_examples/raise_404_if_non_existent.rb'
require 'controllers/shared_examples/setting_project.rb'

RSpec.describe Revisions::FileChangesController, type: :controller do
  let(:master_branch) { project.master_branch }
  let(:project) do
    create :project, :setup_complete, :skip_archive_setup, :with_repository
  end
  let!(:revision) { create :vcs_commit, :published, branch: master_branch }
  let!(:diff)     { create :vcs_file_diff, commit: revision }
  let(:default_params) do
    {
      profile_handle: project.owner.to_param,
      project_slug:   project.slug,
      revision_id:    revision.id,
      id:             diff.hashed_file_id
    }
  end
  let(:current_account) { project.owner.account }
  before                { sign_in current_account }

  let(:is_modification) { true }
  let(:content_change)  { instance_double VCS::Operations::ContentDiffer }

  before do
    allow_any_instance_of(VCS::FileDiff)
      .to receive(:modification?).and_return is_modification
    allow_any_instance_of(VCS::FileDiff)
      .to receive(:content_change).and_return content_change
  end

  describe 'GET #show' do
    let(:params)      { default_params }
    let(:run_request) { get :show, params: params }

    it_should_behave_like 'setting project where setup is complete'
    it_should_behave_like 'raise 404 if non-existent', VCS::Commit
    it_should_behave_like 'raise 404 if non-existent', VCS::FileDiff
    it_should_behave_like 'raise 404 if non-existent', nil do
      # when this is not a modification
      let(:is_modification) { false }
    end
    it_should_behave_like 'raise 404 if non-existent', nil do
      # when this is not a content change
      let(:content_change) { nil }
    end
    it_should_behave_like 'authorizing project access'

    it 'returns http success' do
      run_request
      expect(response).to have_http_status :success
    end
  end
end
