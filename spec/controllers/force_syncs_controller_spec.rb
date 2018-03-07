# frozen_string_literal: true

require 'controllers/shared_examples/raise_404_if_non_existent.rb'

RSpec.describe ForceSyncsController, type: :controller do
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

  before { project.root_folder = root }

  describe 'POST #create' do
    let(:params)      { default_params }
    let(:run_request) { post :create, params: params }

    before do
      allow_any_instance_of(FileResource).to receive(:pull)
      allow_any_instance_of(FileResource).to receive(:pull_children)
    end

    it_should_behave_like 'raise 404 if non-existent', Profiles::Base
    it_should_behave_like 'raise 404 if non-existent', Project
    it_should_behave_like 'raise 404 if non-existent', nil do
      # when file does not exist and never has
      before { default_params[:id] = 'some-nonexistent-id' }
    end

    it 'redirects to file infos page with success message' do
      run_request
      expect(response).to redirect_to(
        profile_project_file_infos_path(project.owner, project, params[:id])
      )
      is_expected.to set_flash[:notice].to 'File successfully synced.'
    end

    it 'calls #pull on file' do
      expect_any_instance_of(FileResource).to receive(:pull)
      run_request
    end

    context 'when file is a folder' do
      it 'calls #pull_children' do
        expect_any_instance_of(FileResource)
          .to receive(:folder?).and_return true
        expect_any_instance_of(FileResource).to receive(:pull_children)
        run_request
      end
    end

    context 'when id is of root folder' do
      before      { params[:id] = root.external_id }

      it 'raises a 404 error' do
        expect { run_request }.to raise_error ActiveRecord::RecordNotFound
      end
    end
  end
end
