# frozen_string_literal: true

require 'lib/shared_contexts/rake.rb'

RSpec.describe 'data_migration:file_versions_content', :archived do
  include_context 'rake'

  let(:run_the_task) { subject.invoke }

  let!(:versions) { create_list(:vcs_version, 3) }

  before { allow(STDOUT).to receive(:puts) }

  before do
    # verify that content ID is null
    versions.each do |version|
      expect(version.content_id).to be_nil
    end
  end

  it 'creates a content for each version' do
    run_the_task

    versions.each do |version|
      version.reload
      expect(version.content).to have_attributes(
        repository_id: version.repository.id
      )
      expect(VCS::RemoteContent).to be_exists(
        repository_id: version.repository.id,
        content_id: version.content_id,
        remote_file_id: version.remote_file_id,
        remote_content_version_id: version.content_version
      )
    end
  end

  context 'when multiple versions have the same content version' do
    let(:versions) do
      create_list :vcs_version, 2,
                  file: fr, remote_file_id: 'id', content_version: 'v'
    end
    let(:fr) { create :vcs_file }

    it 'assigns both versions the same content' do
      run_the_task

      expect(VCS::Content.count).to eq 1
      expect(versions.first.content_id).to eq(versions.second.content_id)
    end
  end
end
