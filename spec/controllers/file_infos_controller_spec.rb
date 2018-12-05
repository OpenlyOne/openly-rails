# frozen_string_literal: true

require 'controllers/shared_examples/authorizing_project_access.rb'
require 'controllers/shared_examples/raise_404_if_non_existent.rb'
require 'controllers/shared_examples/setting_project.rb'

RSpec.describe FileInfosController, type: :controller do
  let!(:root)   { create :vcs_file_in_branch, :root, branch: master_branch }
  let!(:folder) { create :vcs_file_in_branch, :folder, parent_in_branch: root }
  let(:master_branch) { project.master_branch }
  let(:project) do
    create :project, :setup_complete, :skip_archive_setup, :with_repository
  end
  let(:default_params) do
    {
      profile_handle: project.owner.to_param,
      project_slug:   project.slug,
      id:             folder.hashed_file_id
    }
  end
  let(:current_account) { project.owner.account }
  before                { sign_in current_account }

  describe 'GET #index' do
    let(:params)      { default_params }
    let(:run_request) { get :index, params: params }

    it_should_behave_like 'setting project where setup is complete'
    it_should_behave_like 'raise 404 if non-existent', nil do
      # when file does not exist and never has
      before { default_params[:id] = 'some-nonexistent-id' }
    end
    it_should_behave_like 'authorizing project access'

    context 'when id is of root folder' do
      before      { params[:id] = root.remote_file_id }

      it 'raises a 404 error' do
        expect { run_request }.to raise_error ActiveRecord::RecordNotFound
      end
    end

    it 'returns http success' do
      run_request
      expect(response).to have_http_status :success
    end

    context 'when using remote file ID (instead of hashed file ID)' do
      before { default_params.merge(id: folder.remote_file_id) }

      it 'successfully completes the request' do
        run_request
        expect(response).to have_http_status :success
      end
    end
  end
end
