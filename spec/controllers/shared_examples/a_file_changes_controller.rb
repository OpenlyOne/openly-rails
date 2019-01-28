# frozen_string_literal: true

require 'controllers/shared_examples/authorizing_project_access.rb'
require 'controllers/shared_examples/raise_404_if_non_existent.rb'
require 'controllers/shared_examples/setting_project.rb'

# Expect the controller action to redirect and set flash message
RSpec.shared_examples 'a file changes controller' do
  let(:is_modification) { true }
  let(:content_change)  { instance_double VCS::Operations::ContentDiffer }

  before do
    allow_any_instance_of(VCS::FileDiff)
      .to receive(:modification?).and_return is_modification
    allow_any_instance_of(VCS::FileDiff)
      .to receive(:content_change).and_return content_change
  end

  describe 'GET #show' do
    let(:params)      { default_params }
    let(:run_request) { get :show, params: params }

    it_should_behave_like 'setting project where setup is complete'
    it_should_behave_like 'raise 404 if non-existent', nil do
      # when this is not a modification
      let(:is_modification) { false }
    end
    it_should_behave_like 'raise 404 if non-existent', nil do
      # when this is not a content change
      let(:content_change) { nil }
    end
    it_should_behave_like 'authorizing project access'

    context 'when id is of root folder' do
      before      { params[:id] = root.hashed_file_id }

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
