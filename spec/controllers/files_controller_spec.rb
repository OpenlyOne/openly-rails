# frozen_string_literal: true

require 'controllers/shared_examples/an_authenticated_action.rb'
require 'controllers/shared_examples/an_authorized_action.rb'
require 'controllers/shared_examples/raise_404_if_non_existent.rb'

RSpec.describe FilesController, type: :controller do
  let!(:project)        { create(:project) }
  let!(:file)           { project.files.find 'Overview' }
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

    include_examples 'raise 404 if non-existent', Handle
    include_examples 'raise 404 if non-existent', Project

    it 'returns http success' do
      run_request
      expect(response).to have_http_status :success
    end
  end

  describe 'GET #show' do
    let(:params)      { default_params }
    let(:run_request) { get :show, params: params }

    include_examples 'raise 404 if non-existent', Handle
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
    include_examples 'raise 404 if non-existent', Handle
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
    include_examples 'raise 404 if non-existent', Handle
    include_examples 'raise 404 if non-existent', Project
    it_should_behave_like 'raise 404 if non-existent', nil do
      before { allow(file).to receive(:name).and_return 'test' }
    end
    it_should_behave_like 'an authorized action' do
      let(:redirect_location) do
        profile_project_file_path(project.owner, project, file)
      end
    end

    it 'updates the file' do
      expect_any_instance_of(VersionControl::File)
        .to receive(:update)
        .with(hash_including(:content, :revision_summary, :revision_author))
        .with(hash_excluding(:name))
      run_request
    end

    it 'redirects to file' do
      run_request
      expect(response)
        .to redirect_to profile_project_file_path(project.owner, project, file)
    end

    it 'sets flash message' do
      run_request
      is_expected.to set_flash[:notice].to 'File successfully updated.'
    end
  end

  describe 'GET #edit_name' do
    let(:params)      { default_params }
    let(:run_request) { get :edit_name, params: params }
    before            { sign_in project.owner.account }

    it_should_behave_like 'an authenticated action'
    include_examples 'raise 404 if non-existent', Handle
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
    include_examples 'raise 404 if non-existent', Handle
    include_examples 'raise 404 if non-existent', Project
    it_should_behave_like 'raise 404 if non-existent', nil do
      before { allow(file).to receive(:name).and_return 'test' }
    end
    it_should_behave_like 'an authorized action' do
      let(:redirect_location) do
        profile_project_file_path(project.owner, project, file)
      end
    end

    it 'updates the file' do
      expect_any_instance_of(VersionControl::File)
        .to receive(:update)
        .with(hash_including(:name, :revision_summary, :revision_author))
        .with(hash_excluding(:content))
      run_request
    end

    it 'redirects to file' do
      run_request
      expect(response).to redirect_to profile_project_file_path(
        project.owner, project, new_file_name
      )
    end

    it 'sets flash message' do
      run_request
      is_expected.to set_flash[:notice].to 'File successfully updated.'
    end
  end
end
