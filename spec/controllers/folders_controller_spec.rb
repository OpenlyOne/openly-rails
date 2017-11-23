# frozen_string_literal: true

require 'controllers/shared_examples/raise_404_if_non_existent.rb'

RSpec.describe FoldersController, type: :controller do
  before { allow(NotificationChannelJob).to receive(:perform_later) }
  let!(:folder)         { create(:file_items_folder) }
  let(:project)         { folder.project }
  let(:default_params)  do
    {
      profile_handle:   project.owner.to_param,
      project_slug:     project.slug,
      google_drive_id:  folder.google_drive_id
    }
  end

  describe 'GET #root' do
    let(:params)      { default_params.except :google_drive_id }
    let(:run_request) { get :root, params: params }

    include_examples 'raise 404 if non-existent', Profiles::Base
    include_examples 'raise 404 if non-existent', Project
    include_examples 'raise 404 if non-existent', FileItems::Base

    it 'returns http success' do
      run_request
      expect(response).to have_http_status :success
    end
  end

  describe 'GET #show' do
    let(:params)      { default_params }
    let(:run_request) { get :show, params: params }

    include_examples 'raise 404 if non-existent', Profiles::Base
    include_examples 'raise 404 if non-existent', Project
    include_examples 'raise 404 if non-existent', FileItems::Base

    it 'returns http success' do
      run_request
      expect(response).to have_http_status :success
    end
  end
end
