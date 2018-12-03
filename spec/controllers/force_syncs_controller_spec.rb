# frozen_string_literal: true

require 'controllers/shared_examples/an_authenticated_action.rb'
require 'controllers/shared_examples/an_authorized_action.rb'
require 'controllers/shared_examples/authorizing_project_access.rb'
require 'controllers/shared_examples/raise_404_if_non_existent.rb'
require 'controllers/shared_examples/setting_project.rb'

RSpec.describe ForceSyncsController, type: :controller do
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
      id:             folder.remote_file_id
    }
  end

  let(:current_account) { project.owner.account }
  before                { sign_in current_account }

  describe 'POST #create' do
    let(:params)      { default_params }
    let(:run_request) { post :create, params: params }

    before do
      allow_any_instance_of(VCS::FileInBranch)
        .to receive(:backup_on_save?).and_return false
      allow_any_instance_of(VCS::FileInBranch).to receive(:pull)
      allow_any_instance_of(VCS::FileInBranch).to receive(:pull_children)
    end

    it_should_behave_like 'an authenticated action'
    it_should_behave_like 'setting project where setup is complete'
    it_should_behave_like 'raise 404 if non-existent', nil do
      # when file does not exist and never has
      before { default_params[:id] = 'some-nonexistent-id' }
    end
    it_should_behave_like 'an authorized action' do
      let(:redirect_location) do
        profile_project_file_infos_path(project.owner, project, params[:id])
      end
      let(:unauthorized_message) do
        'You are not authorized to force sync files of this project.'
      end
    end
    it_should_behave_like 'authorizing project access'

    it 'redirects to file infos page with success message' do
      run_request
      expect(response).to redirect_to(
        profile_project_file_infos_path(project.owner, project, params[:id])
      )
      is_expected.to set_flash[:notice].to 'File successfully synced.'
    end

    it 'calls #pull on file' do
      expect_any_instance_of(VCS::FileInBranch).to receive(:pull)
      run_request
    end

    context 'when file is a folder' do
      it 'calls #pull_children' do
        expect_any_instance_of(VCS::FileInBranch)
          .to receive(:folder?).and_return true
        expect_any_instance_of(VCS::FileInBranch).to receive(:pull_children)
        run_request
      end
    end

    context 'when id is of root folder' do
      before      { params[:id] = root.remote_file_id }

      it 'raises a 404 error' do
        expect { run_request }.to raise_error ActiveRecord::RecordNotFound
      end
    end
  end
end
