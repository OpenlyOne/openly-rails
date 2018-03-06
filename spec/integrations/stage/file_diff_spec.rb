# frozen_string_literal: true

RSpec.describe Stage::FileDiff, type: :model do
  describe '#find_by!(external_id:, project:)' do
    subject(:find) do
      Stage::FileDiff.find_by!(external_id: external_id, project: project)
    end
    let(:external_id)   { file_resource.external_id }
    let(:project)       { create :project }
    let(:revision)      { create :revision, project: project }
    let(:file_resource) { create :file_resource }
    let(:add_to_stage)  { project.file_resources_in_stage << file_resource }
    let(:add_to_last_revision) do
      revision.committed_files.create!(
        file_resource: file_resource, file_resource_snapshot: committed_snapshot
      )
    end
    let(:committed_snapshot) do
      file_resource.update!(name: 'new-name')
      file_resource.snapshots.first
    end
    let(:publish_revision) { revision.update!(is_published: true, title: 't') }

    before { add_to_stage }
    before { add_to_last_revision }
    before { publish_revision }

    context 'when file is in both stage and last revision' do
      it 'sets staged_snapshot' do
        expect(find.staged_snapshot.id).to eq file_resource.current_snapshot_id
      end

      it 'sets committed_snapshot' do
        expect(find.committed_snapshot.id).to eq committed_snapshot.id
      end
    end

    context 'when file exists only in stage' do
      let(:add_to_last_revision) { nil }

      it 'sets staged_snapshot' do
        expect(find.staged_snapshot.id).to eq file_resource.current_snapshot_id
      end

      it { expect(find.committed_snapshot).to be_nil }
    end

    context 'when file exists only in last revision' do
      let(:add_to_stage) { nil }

      it { expect(find.staged_snapshot).to be_nil }

      it 'sets committed_snapshot' do
        expect(find.committed_snapshot.id).to eq committed_snapshot.id
      end
    end

    context 'when file is in neither stage nor last revision' do
      let(:add_to_stage) { nil }
      let(:add_to_last_revision) { nil }

      it { expect { find }.to raise_error ActiveRecord::RecordNotFound }
    end

    context 'when file resource does not exist' do
      let(:external_id) { 'non-existing-id' }

      it { expect { find }.to raise_error ActiveRecord::RecordNotFound }
    end

    context 'when project does not have a published last revision' do
      let(:publish_revision) { nil }

      it 'sets staged_snapshot' do
        expect(find.staged_snapshot.id).to eq file_resource.current_snapshot_id
      end

      it { expect(find.committed_snapshot).to be_nil }
    end

    context 'when project does not have a last revision' do
      let(:revision)              { nil }
      let(:add_to_last_revision)  { nil }
      let(:publish_revision)      { nil }

      it 'sets staged_snapshot' do
        expect(find.staged_snapshot.id).to eq file_resource.current_snapshot_id
      end

      it { expect(find.committed_snapshot).to be_nil }
    end
  end
end
