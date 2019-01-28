# frozen_string_literal: true

require 'controllers/shared_examples/a_file_changes_controller.rb'

RSpec.describe FileChangesController, type: :controller do
  let!(:root) { create :vcs_file_in_branch, :root, branch: master_branch }
  let!(:file) { create :vcs_file_in_branch, parent_in_branch: root }
  let(:master_branch) { project.master_branch }
  let(:project) do
    create :project, :setup_complete, :skip_archive_setup, :with_repository
  end
  let(:default_params) do
    {
      profile_handle: project.owner.to_param,
      project_slug:   project.slug,
      id:             file.hashed_file_id
    }
  end
  let(:current_account) { project.owner.account }
  before                { sign_in current_account }

  it_should_behave_like 'a file changes controller'
end
