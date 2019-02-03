# frozen_string_literal: true

require 'controllers/shared_examples/an_authenticated_action.rb'
require 'controllers/shared_examples/an_authorized_action.rb'
require 'controllers/shared_examples/authorizing_project_access.rb'
require 'controllers/shared_examples/raise_404_if_non_existent.rb'
require 'controllers/shared_examples/setting_project.rb'

RSpec.shared_examples 'a force syncs controller' do
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
      let(:redirect_location)     { redirect_location_when_unauthorized }
      let(:unauthorized_message)  { message_when_unauthorized }
    end
    it_should_behave_like 'authorizing project access'

    it 'redirects to file infos page with success message' do
      run_request
      expect(response).to redirect_to(redirect_location_when_successful)
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
