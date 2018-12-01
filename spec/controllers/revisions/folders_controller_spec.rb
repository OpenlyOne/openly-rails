# frozen_string_literal: true

require 'controllers/shared_examples/authorizing_project_access.rb'
require 'controllers/shared_examples/raise_404_if_non_existent.rb'
require 'controllers/shared_examples/setting_project.rb'

RSpec.describe Revisions::FoldersController, type: :controller do
  let!(:root)         { create :vcs_staged_file, :root, branch: master_branch }
  let!(:folder)       { create :vcs_staged_file, :folder, parent: root }
  let(:master_branch) { project.master_branch }
  let(:project) do
    create :project, :setup_complete, :skip_archive_setup, :with_repository
  end
  let(:revision) { create :vcs_commit, branch: master_branch }
  let!(:committed_folder) do
    create :vcs_committed_file,
           file_snapshot: folder.current_snapshot, commit: revision
  end
  let!(:committed_file) do
    create :vcs_committed_file, commit: revision
  end
  let(:default_params) do
    {
      profile_handle: project.owner.to_param,
      project_slug:   project.slug,
      revision_id:    revision.id,
      id:             folder.remote_file_id
    }
  end
  let(:current_account) { project.owner.account }
  before                { sign_in current_account }
  before                { revision.update(is_published: true, title: 'origin') }

  describe 'GET #root' do
    let(:params)          { default_params.except :id }
    let(:run_request)     { get :root, params: params }

    it_should_behave_like 'setting project where setup is complete'
    it_should_behave_like 'raise 404 if non-existent', VCS::Commit
    it_should_behave_like 'authorizing project access'

    it 'returns http success' do
      run_request
      expect(response).to have_http_status :success
    end
  end

  describe 'GET #show' do
    let(:params)          { default_params }
    let(:run_request)     { get :show, params: params }

    it_should_behave_like 'setting project where setup is complete'
    it_should_behave_like 'raise 404 if non-existent', VCS::Commit
    it_should_behave_like 'authorizing project access'

    context 'when file is not a directory' do
      before { params[:id] = committed_file.file_snapshot.remote_file_id }

      it 'raises a 404 error' do
        expect { run_request }.to raise_error ActiveRecord::RecordNotFound
      end
    end

    it 'returns http success' do
      run_request
      expect(response).to have_http_status :success
    end
  end
end
