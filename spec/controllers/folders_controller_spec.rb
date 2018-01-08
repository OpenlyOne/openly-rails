# frozen_string_literal: true

require 'controllers/shared_examples/a_repository_locking_action.rb'
require 'controllers/shared_examples/raise_404_if_non_existent.rb'

RSpec.describe FoldersController, type: :controller do
  let!(:folder)         { create :file, :root, repository: project.repository }
  let(:project)         { create :project }
  let(:default_params)  do
    {
      profile_handle: project.owner.to_param,
      project_slug:   project.slug,
      id:             folder.id
    }
  end

  describe 'GET #root' do
    let(:params)      { default_params.except :id }
    let(:run_request) { get :root, params: params }

    include_examples 'raise 404 if non-existent', Profiles::Base
    include_examples 'raise 404 if non-existent', Project
    it_should_behave_like 'raise 404 if non-existent', nil do
      # when folder does not exist
      before { FileUtils.remove_dir(folder.send(:path)) }
    end
    it_should_behave_like 'a repository locking action'

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
    it_should_behave_like 'raise 404 if non-existent', nil do
      # when folder does not exist
      before { FileUtils.remove_dir(folder.send(:path)) }
    end
    it_should_behave_like 'a repository locking action'

    context 'when file is not a directory' do
      let(:file)  { create :file, parent: folder }
      before      { params[:id] = file.id }

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
