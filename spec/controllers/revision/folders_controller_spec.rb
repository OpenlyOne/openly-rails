# frozen_string_literal: true

require 'controllers/shared_examples/authorizing_project_access.rb'
require 'controllers/shared_examples/raise_404_if_non_existent.rb'
require 'controllers/shared_examples/setting_project.rb'

RSpec.describe Revision::FoldersController, type: :controller do
  let(:root)    { create :file_resource, :folder }
  let(:folder)  { create :file_resource, :folder, parent: root }
  let(:project) { create :project, :setup_complete, :skip_archive_setup }
  let!(:revision) do
    # project.revisions.create_draft_and_commit_files!(project.owner).tap do |r|
    #   r.update(title: 'origin', is_published: true)
    # end
    create :revision, :published, project: project
  end
  let(:default_params) do
    {
      profile_handle: project.owner.to_param,
      project_slug:   project.slug,
      revision_id:    revision.id,
      id:             folder.external_id
    }
  end
  let(:current_account) { project.owner.account }
  before                { sign_in current_account }
  before                { project.root_folder = root }

  describe 'GET #root' do
    let(:params)          { default_params.except :id }
    let(:run_request)     { get :root, params: params }

    it_should_behave_like 'setting project where setup is complete'
    it_should_behave_like 'raise 404 if non-existent', Revision
    it_should_behave_like 'authorizing project access'

    it 'returns http success' do
      run_request
      expect(response).to have_http_status :success
    end
  end
end
