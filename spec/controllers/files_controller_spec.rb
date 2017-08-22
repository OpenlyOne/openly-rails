# frozen_string_literal: true

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
end
