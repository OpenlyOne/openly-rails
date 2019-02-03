# frozen_string_literal: true

require 'controllers/shared_examples/a_file_changes_controller.rb'

RSpec.describe Revisions::FileChangesController, type: :controller do
  let(:master_branch) { project.master_branch }
  let!(:root) { create :vcs_file_in_branch, :root, branch: master_branch }
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

  it_should_behave_like 'a file changes controller'
end
