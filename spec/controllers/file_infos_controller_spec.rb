# frozen_string_literal: true

require 'controllers/shared_examples/raise_404_if_non_existent.rb'
require 'controllers/shared_examples/authorizing_project_access.rb'

RSpec.describe FileInfosController, type: :controller do
  let(:root)    { create :file_resource, :folder }
  let(:folder)  { create :file_resource, :folder, parent: root }
  let(:project) { create :project }
  let(:default_params) do
    {
      profile_handle: project.owner.to_param,
      project_slug:   project.slug,
      id:             folder.external_id
    }
  end
  let(:current_account) { project.owner.account }
  before                { sign_in current_account }
  before                { project.root_folder = root }

  describe 'GET #index' do
    let(:params)      { default_params }
    let(:run_request) { get :index, params: params }

    it_should_behave_like 'raise 404 if non-existent', Profiles::Base
    it_should_behave_like 'raise 404 if non-existent', Project
    it_should_behave_like 'raise 404 if non-existent', nil do
      # when file does not exist and never has
      before { default_params[:id] = 'some-nonexistent-id' }
    end
    it_should_behave_like 'authorizing project access'

    context 'when id is of root folder' do
      before      { params[:id] = root.external_id }

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
