# frozen_string_literal: true

require 'controllers/shared_examples/a_redirect_with_success.rb'
require 'controllers/shared_examples/an_authenticated_action.rb'
require 'controllers/shared_examples/an_authorized_action.rb'
require 'controllers/shared_examples/raise_404_if_non_existent.rb'

RSpec.describe FilesController, type: :controller do
  let!(:project)        { create(:project) }
  let!(:file)           { create(:vc_file, collection: project.files) }
  let(:default_params)  do
    {
      profile_handle: project.owner,
      project_slug:   project.slug,
      name:           file.name
    }
  end

  describe 'GET #index' do
    let(:params)      { default_params.except :name }
    let(:run_request) { get :index, params: params }

    include_examples 'raise 404 if non-existent', Profiles::Base
    include_examples 'raise 404 if non-existent', Project

    it 'returns http success' do
      run_request
      expect(response).to have_http_status :success
    end
  end

  describe 'GET #new' do
    let(:params)      { default_params.except :name }
    let(:run_request) { get :new, params: params }
    before            { sign_in project.owner.account }

    it_should_behave_like 'an authenticated action'
    include_examples 'raise 404 if non-existent', Profiles::Base
    include_examples 'raise 404 if non-existent', Project
    it_should_behave_like 'an authorized action' do
      let(:redirect_location) do
        profile_project_files_path(project.owner, project)
      end
    end

    it 'returns http success' do
      run_request
      expect(response).to have_http_status :success
    end
  end

  describe 'POST #create' do
    let(:add_params) do
      {
        version_control_file: {
          name: 'name',
          content: 'content',
          revision_summary: 'summary'
        }
      }
    end
    let(:params)      { default_params.except(:name).merge(add_params) }
    let(:run_request) { post :create, params: params }
    before            { sign_in project.owner.account }

    it_should_behave_like 'an authenticated action'
    include_examples 'raise 404 if non-existent', Profiles::Base
    include_examples 'raise 404 if non-existent', Project
    it_should_behave_like 'an authorized action' do
      let(:redirect_location) do
        profile_project_files_path(project.owner, project)
      end
    end
    it_should_behave_like 'a redirect with success' do
      let(:redirect_location) do
        profile_project_file_path(project.owner, project, 'name')
      end
    end

    it 'saves the file' do
      expect_any_instance_of(VersionControl::File)
        .to receive(:update)
        .with(
          hash_including(:content, :name, :revision_summary, :revision_author)
        )
        .and_call_original
      expect_any_instance_of(VersionControl::File).to receive(:save)
      run_request
    end

    it 'increments the files count' do
      file_count = project.files.reload!.count
      run_request
      expect(project.reload.files_count).to eq file_count + 1
    end
  end

  describe 'GET #show' do
    let(:params)      { default_params }
    let(:run_request) { get :show, params: params }

    include_examples 'raise 404 if non-existent', Profiles::Base
    include_examples 'raise 404 if non-existent', Project
    it_should_behave_like 'raise 404 if non-existent', nil do
      before { allow(file).to receive(:name).and_return 'test' }
    end

    it 'returns http success' do
      run_request
      expect(response).to have_http_status :success
    end
  end

  describe 'GET #edit_content' do
    let(:params)      { default_params }
    let(:run_request) { get :edit_content, params: params }
    before            { sign_in project.owner.account }

    it_should_behave_like 'an authenticated action'
    include_examples 'raise 404 if non-existent', Profiles::Base
    include_examples 'raise 404 if non-existent', Project
    it_should_behave_like 'raise 404 if non-existent', nil do
      before { allow(file).to receive(:name).and_return 'test' }
    end
    it_should_behave_like 'an authorized action' do
      let(:redirect_location) do
        profile_project_file_path(project.owner, project, file)
      end
    end

    it 'returns http success' do
      run_request
      expect(response).to have_http_status :success
    end
  end

  describe 'PATCH #update_content' do
    let(:add_params) do
      {
        version_control_file: {
          content: 'content',
          revision_summary: 'summary'
        }
      }
    end
    let(:params)      { default_params.merge(add_params) }
    let(:run_request) { put :update_content, params: params }
    before            { sign_in project.owner.account }

    it_should_behave_like 'an authenticated action'
    include_examples 'raise 404 if non-existent', Profiles::Base
    include_examples 'raise 404 if non-existent', Project
    it_should_behave_like 'raise 404 if non-existent', nil do
      before { allow(file).to receive(:name).and_return 'test' }
    end
    it_should_behave_like 'an authorized action' do
      let(:redirect_location) do
        profile_project_file_path(project.owner, project, file)
      end
    end
    it_should_behave_like 'a redirect with success' do
      let(:redirect_location) do
        profile_project_file_path(project.owner, project, file)
      end
      let(:inflected_action_name) { 'updated' }
    end

    it 'updates the file' do
      expect_any_instance_of(VersionControl::File)
        .to receive(:update)
        .with(hash_including(:content, :revision_summary, :revision_author))
        .with(hash_excluding(:name))
      run_request
    end
  end

  describe 'GET #edit_name' do
    let(:params)      { default_params }
    let(:run_request) { get :edit_name, params: params }
    before            { sign_in project.owner.account }

    it_should_behave_like 'an authenticated action'
    include_examples 'raise 404 if non-existent', Profiles::Base
    include_examples 'raise 404 if non-existent', Project
    it_should_behave_like 'raise 404 if non-existent', nil do
      before { allow(file).to receive(:name).and_return 'test' }
    end
    it_should_behave_like 'an authorized action' do
      let(:redirect_location) do
        profile_project_file_path(project.owner, project, file)
      end
    end

    it 'returns http success' do
      run_request
      expect(response).to have_http_status :success
    end
  end

  describe 'PATCH #update_name' do
    let(:add_params) do
      {
        version_control_file: {
          name: new_file_name,
          revision_summary: 'summary'
        }
      }
    end
    let(:params)        { default_params.merge(add_params) }
    let(:run_request)   { put :update_name, params: params }
    let(:new_file_name) { 'name' }
    before              { sign_in project.owner.account }

    it_should_behave_like 'an authenticated action'
    include_examples 'raise 404 if non-existent', Profiles::Base
    include_examples 'raise 404 if non-existent', Project
    it_should_behave_like 'raise 404 if non-existent', nil do
      before { allow(file).to receive(:name).and_return 'test' }
    end
    it_should_behave_like 'an authorized action' do
      let(:redirect_location) do
        profile_project_file_path(project.owner, project, file)
      end
    end
    it_should_behave_like 'a redirect with success' do
      let(:redirect_location) do
        profile_project_file_path(project.owner, project, 'name')
      end
      let(:inflected_action_name) { 'updated' }
    end

    it 'updates the file' do
      expect_any_instance_of(VersionControl::File)
        .to receive(:update)
        .with(hash_including(:name, :revision_summary, :revision_author))
        .with(hash_excluding(:content))
      run_request
    end
  end

  describe 'GET #delete' do
    let(:params)      { default_params }
    let(:run_request) { get :delete, params: params }
    before            { sign_in project.owner.account }

    it_should_behave_like 'an authenticated action'
    include_examples 'raise 404 if non-existent', Profiles::Base
    include_examples 'raise 404 if non-existent', Project
    it_should_behave_like 'raise 404 if non-existent', nil do
      before { allow(file).to receive(:name).and_return 'test' }
    end
    it_should_behave_like 'an authorized action' do
      let(:redirect_location) do
        profile_project_file_path(project.owner, project, file)
      end
    end

    it 'returns http success' do
      run_request
      expect(response).to have_http_status :success
    end
  end

  describe 'DELETE #destroy' do
    let(:add_params) do
      {
        version_control_file: {
          revision_summary: 'summary'
        }
      }
    end
    let(:params)      { default_params.merge(add_params) }
    let(:run_request) { delete :destroy, params: params }
    before            { sign_in project.owner.account }

    it_should_behave_like 'an authenticated action'
    include_examples 'raise 404 if non-existent', Profiles::Base
    include_examples 'raise 404 if non-existent', Project
    it_should_behave_like 'raise 404 if non-existent', nil do
      before { allow(file).to receive(:name).and_return 'test' }
    end
    it_should_behave_like 'an authorized action' do
      let(:redirect_location) do
        profile_project_file_path(project.owner, project, file)
      end
    end
    it_should_behave_like 'a redirect with success' do
      let(:redirect_location) do
        profile_project_files_path(project.owner, project)
      end
    end

    it 'destroys the file' do
      expect_any_instance_of(VersionControl::File).to receive(:destroy)
      run_request
    end

    it 'decrements the files count' do
      file_count = project.files.reload!.count
      run_request
      expect(project.reload.files_count).to eq file_count - 1
    end

    context 'when destruction of file fails' do
      before do
        allow_any_instance_of(VersionControl::File)
          .to receive(:destroy)
          .and_return false
      end

      it 'does not redirect' do
        run_request
        expect(response).not_to have_http_status :redirect
      end

      it 'does not set flash message' do
        run_request
        is_expected.not_to set_flash
      end
    end
  end
end
