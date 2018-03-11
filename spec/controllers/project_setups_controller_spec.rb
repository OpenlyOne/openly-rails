# frozen_string_literal: true

require 'controllers/shared_examples/raise_404_if_non_existent.rb'
require 'controllers/shared_examples/successfully_rendering_view.rb'

RSpec.describe ProjectSetupsController, type: :controller do
  let!(:project)      { create :project }
  let(:file_resource) { create :file_resource, :folder }
  let(:link)          { file_resource.external_link }
  let(:default_params) do
    {
      profile_handle: project.owner.to_param,
      project_slug:   project.slug
    }
  end

  describe 'GET #new' do
    let(:params)      { default_params }
    let(:run_request) { get :new, params: params }

    it_should_behave_like 'raise 404 if non-existent', Profiles::Base
    it_should_behave_like 'raise 404 if non-existent', Project

    it 'returns http success' do
      run_request
      expect(response).to have_http_status :success
    end
  end

  describe 'POST #create', :delayed_job do
    let(:params)      { default_params.merge(add_params) }
    let(:run_request) { post :create, params: params }
    let(:add_params) do
      {
        project_setup: {
          link: file_resource.external_link
        }
      }
    end

    it_should_behave_like 'raise 404 if non-existent', Profiles::Base
    it_should_behave_like 'raise 404 if non-existent', Project

    it 'redirects to project setup page with success message' do
      run_request
      expect(response).to redirect_to(
        profile_project_setup_path(project.owner, project)
      )
      is_expected.to set_flash[:notice].to('Files are being imported...')
    end

    it 'calls #begin on setup' do
      expect_any_instance_of(Project::Setup).to receive(:begin)
      run_request
    end

    context 'when #begin fails' do
      before do
        allow_any_instance_of(Project::Setup)
          .to receive(:begin).and_return false
      end

      it_should_behave_like 'successfully rendering view'
    end
  end

  describe 'GET #show' do
    let(:params)      { default_params }
    let(:run_request) { get :show, params: params }

    it_should_behave_like 'raise 404 if non-existent', Profiles::Base
    it_should_behave_like 'raise 404 if non-existent', Project

    it 'returns http success' do
      run_request
      expect(response).to have_http_status :success
    end
  end
end
