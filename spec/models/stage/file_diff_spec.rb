# frozen_string_literal: true

require 'models/shared_examples/being_diffing.rb'

RSpec.describe Stage::FileDiff, type: :model do
  before { skip('Model is pending deletion') }

  subject(:diff) { build :staged_file_diff }

  it_should_behave_like 'being diffing' do
    let(:diffing) { diff }
  end

  describe 'attributes' do
    it { should respond_to :project }
    it { should respond_to :project= }
    it { should respond_to :staged_snapshot }
    it { should respond_to :staged_snapshot= }
    it { should respond_to :committed_snapshot }
    it { should respond_to :committed_snapshot= }
  end

  describe '.find_by!(external_id:, project:)' do
    subject(:find) do
      Stage::FileDiff.find_by!(external_id: 'external-id', project: 'project')
    end
    let(:staged_snapshot)     { 'staged-snapshot' }
    let(:committed_snapshot)  { 'staged-snapshot' }
    let(:new_diff)            { instance_double described_class }

    before do
      file = instance_double FileResource
      allow(FileResource)
        .to receive(:find_by!).with(external_id: 'external-id').and_return file
      allow(Stage::FileDiff)
        .to receive(:staged_snapshot_for)
        .with(file, 'project')
        .and_return staged_snapshot
      allow(Stage::FileDiff)
        .to receive(:last_committed_snapshot_for)
        .with(file, 'project')
        .and_return committed_snapshot
      allow(Stage::FileDiff)
        .to receive(:new)
        .with(project: 'project',
              staged_snapshot: staged_snapshot,
              committed_snapshot: committed_snapshot)
        .and_return new_diff
    end

    it { is_expected.to eq new_diff }

    context 'when staged_snapshot_for is nil' do
      let(:staged_snapshot) { nil }
      it { is_expected.to eq new_diff }
    end

    context 'when last_committed_snapshot_for is nil' do
      let(:committed_snapshot) { nil }
      it { is_expected.to eq new_diff }
    end

    context 'when both staged_ and last_committed_snapshot_for are nil' do
      let(:staged_snapshot)     { nil }
      let(:committed_snapshot)  { nil }
      it { expect { find }.to raise_error ActiveRecord::RecordNotFound }
    end
  end

  describe '.last_committed_snapshot_for(file, project)' do
    subject { Stage::FileDiff.last_committed_snapshot_for('file', project) }
    let(:project)   { instance_double Project }
    let(:revisions) { ['r1', 'r2', revision] }
    let(:revision)  { instance_double Revision }

    before do
      committed_snapshots = class_double FileResource::Snapshot
      committed_snapshots_with_provider = class_double FileResource::Snapshot
      allow(project).to receive(:revisions).and_return revisions
      allow(revision)
        .to receive(:committed_file_snapshots).and_return committed_snapshots
      allow(committed_snapshots)
        .to receive(:with_provider_id)
        .and_return committed_snapshots_with_provider
      allow(committed_snapshots_with_provider)
        .to receive(:find_by).with(file_resource: 'file').and_return 'snapshot'
    end

    it { is_expected.to eq 'snapshot' }

    context 'when there is no last revision' do
      let(:revisions) { [] }

      it { is_expected.to eq nil }
    end
  end

  describe '#initialize(attributes = {})' do
    subject(:diff) do
      Stage::FileDiff.new(project: 'project',
                          file_resource_id: file_resource_id,
                          staged_snapshot: 'staged-snapshot',
                          committed_snapshot: 'committed-snapshot')
    end
    let(:file_resource_id) { 'resource-id' }

    before do
      allow_any_instance_of(Stage::FileDiff)
        .to receive(:set_file_resource_id_from_snapshots)
    end

    it 'sets project' do
      expect(diff.project).to eq 'project'
    end

    it 'sets file resource id' do
      expect(diff.file_resource_id).to eq 'resource-id'
    end

    it 'sets staged_snapshot' do
      expect(diff.staged_snapshot).to eq 'staged-snapshot'
    end

    it 'sets committed_snapshot' do
      expect(diff.committed_snapshot).to eq 'committed-snapshot'
    end

    context 'when file_resource_id is not passed / nil' do
      let(:file_resource_id) { nil }

      it 'calls #set_file_resource_id_from_snapshots' do
        expect_any_instance_of(Stage::FileDiff)
          .to receive(:set_file_resource_id_from_snapshots)
        diff
      end
    end
  end

  describe '#ancestors_in_project' do
    subject { diff.ancestors_in_project }

    before do
      allow(diff).to receive(:project).and_return 'project'
      allow(diff)
        .to receive(:current_or_previous_snapshot).and_return 'snapshot'

      allow(Stage::FileDiff::Ancestry)
        .to receive(:for)
        .with(project: 'project', file_resource_snapshot: 'snapshot')
        .and_return %w[ancestor1 ancestor2 ancestor3]
    end

    it { is_expected.to eq %w[ancestor1 ancestor2 ancestor3] }
  end

  describe '#children_as_diffs' do
    subject { diff.children_as_diffs }

    before do
      allow(diff).to receive(:project).and_return 'project'
      allow(diff).to receive(:file_resource_id).and_return 'file-id'

      allow(Stage::FileDiff::ChildrenQuery)
        .to receive(:new)
        .with(project: 'project', parent_id: 'file-id')
        .and_return 'query'
    end

    it { is_expected.to eq 'query' }
  end

  describe '#first_three_ancestors' do
    subject { diff.first_three_ancestors }
    let(:a1) { instance_double FileResource::Snapshot }
    let(:a2) { instance_double FileResource::Snapshot }
    let(:a3) { instance_double FileResource::Snapshot }

    before do
      allow(diff).to receive(:project).and_return 'project'
      allow(diff)
        .to receive(:current_or_previous_snapshot).and_return 'snapshot'

      allow(Stage::FileDiff::Ancestry)
        .to receive(:for)
        .with(project: 'project', file_resource_snapshot: 'snapshot', depth: 3)
        .and_return [a1, a2, a3]

      allow(a1).to receive(:name).and_return 'anc1'
      allow(a2).to receive(:name).and_return 'anc2'
      allow(a3).to receive(:name).and_return 'anc3'
    end

    it { is_expected.to eq %w[anc1 anc2 anc3] }
  end

  describe '#snapshot_id' do
    subject { diff.snapshot_id }

    before do
      allow(diff)
        .to receive(:current_or_previous_snapshot_id)
        .and_return 'current-or-previous-snapshot-id'
    end

    it { is_expected.to eq 'current-or-previous-snapshot-id' }
  end
end
