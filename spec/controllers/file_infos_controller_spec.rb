# frozen_string_literal: true

require 'controllers/shared_examples/a_repository_locking_action.rb'
require 'controllers/shared_examples/raise_404_if_non_existent.rb'
require 'controllers/shared_examples/setting_project_context.rb'

RSpec.describe FileInfosController, type: :controller do
  let!(:file)     { create :file, parent: root }
  let(:root)      { create :file, :root, repository: project.repository }
  let!(:project)  { create :project }
  let(:default_params) do
    {
      profile_handle: project.owner.to_param,
      project_slug:   project.slug,
      id:             file.id
    }
  end

  describe 'GET #index' do
    let(:params)      { default_params }
    let(:run_request) { get :index, params: params }

    include_examples 'raise 404 if non-existent', Profiles::Base
    include_examples 'raise 404 if non-existent', Project
    it_should_behave_like 'raise 404 if non-existent', nil do
      # when file does not exist and never has
      before { default_params[:id] = 'some-nonexistent-id' }
    end

    it_should_behave_like 'a repository locking action'
    it_should_behave_like 'setting project context'

    it 'returns http success' do
      run_request
      expect(response).to have_http_status :success
    end
  end
end
