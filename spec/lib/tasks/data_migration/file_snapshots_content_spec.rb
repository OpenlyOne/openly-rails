# frozen_string_literal: true

require 'lib/shared_contexts/rake.rb'

RSpec.describe 'data_migration:file_snapshots_content', :archived do
  include_context 'rake'

  let(:run_the_task) { subject.invoke }

  let!(:snapshots) { create_list(:vcs_file_snapshot, 3) }

  before { allow(STDOUT).to receive(:puts) }

  before do
    # verify that content ID is null
    snapshots.each do |snapshot|
      expect(snapshot.content_id).to be_nil
    end
  end

  it 'creates a content for each snapshot' do
    run_the_task

    snapshots.each do |snapshot|
      snapshot.reload
      expect(snapshot.content).to have_attributes(
        repository_id: snapshot.repository.id
      )
      expect(VCS::RemoteContent).to be_exists(
        repository_id: snapshot.repository.id,
        content_id: snapshot.content_id,
        remote_file_id: snapshot.external_id,
        remote_content_version_id: snapshot.content_version
      )
    end
  end

  context 'when multiple snapshots have the same content version' do
    let(:snapshots) do
      create_list :vcs_file_snapshot, 2,
                  file_record: fr, external_id: 'id', content_version: 'v'
    end
    let(:fr) { create :vcs_file_record }

    it 'assigns both snapshots the same content' do
      run_the_task

      expect(VCS::Content.count).to eq 1
      expect(snapshots.first.content_id).to eq(snapshots.second.content_id)
    end
  end
end
