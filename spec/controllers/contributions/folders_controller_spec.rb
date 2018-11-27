# frozen_string_literal: true

require 'controllers/shared_examples/a_folders_controller.rb'

RSpec.describe Contributions::FoldersController, type: :controller do
  let!(:root)   { create :vcs_file_in_branch, :root, branch: branch }
  let!(:folder) { create :vcs_file_in_branch, :folder, parent_in_branch: root }
  let(:branch)        { contribution.branch }
  let(:contribution)  { create :contribution, project: project }
  let(:project) do
    create :project, :setup_complete, :skip_archive_setup, :with_repository
  end
  let(:default_params) do
    {
      profile_handle:   project.owner.to_param,
      project_slug:     project.slug,
      contribution_id:  contribution.id,
      id:               folder.hashed_file_id
    }
  end
  let(:current_account) { project.owner.account }
  before                { sign_in current_account }

  it_should_behave_like 'a folders controller',
                        require_authentication: false,
                        require_authorization: false
end
