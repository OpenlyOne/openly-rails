# frozen_string_literal: true

require 'controllers/shared_examples/an_authenticated_action.rb'
require 'controllers/shared_examples/an_authorized_action.rb'
require 'controllers/shared_examples/authorizing_project_access.rb'
require 'controllers/shared_examples/raise_404_if_non_existent.rb'
require 'controllers/shared_examples/setting_project.rb'

# Expect the controller action to redirect and set flash message
RSpec.shared_examples 'a folders controller' \
  do |require_authentication:, require_authorization:|

  describe 'GET #root' do
    let(:params)          { default_params.except :id }
    let(:run_request)     { get :root, params: params }

    it_should_behave_like 'an authenticated action' if require_authentication
    it_should_behave_like 'setting project where setup is complete'
    it_should_behave_like 'raise 404 if non-existent', nil do
      before { VCS::FileInBranch.delete_all }
    end
    it_should_behave_like 'authorizing project access'

    if require_authorization
      it_should_behave_like 'an authorized action' do
        let(:redirect_location) do
          profile_project_path(project.owner, project)
        end
        let(:unauthorized_message) do
          'You are not authorized to view work in progress for this project.'
        end
      end
    end

    it 'returns http success' do
      run_request
      expect(response).to have_http_status :success
    end
  end

  describe 'GET #show' do
    let(:params)          { default_params }
    let(:run_request)     { get :show, params: params }

    it_should_behave_like 'an authenticated action' if require_authentication
    it_should_behave_like 'setting project where setup is complete'
    it_should_behave_like 'raise 404 if non-existent', nil do
      before { VCS::FileInBranch.delete_all }
    end
    it_should_behave_like 'authorizing project access'
    if require_authorization
      it_should_behave_like 'an authorized action' do
        let(:redirect_location) do
          profile_project_path(project.owner, project)
        end
        let(:unauthorized_message) do
          'You are not authorized to view work in progress for this project.'
        end
      end
    end

    context 'when file is not a directory' do
      let(:file)  { create :vcs_file_in_branch, parent_in_branch: folder }
      before      { params[:id] = file.remote_file_id }

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
