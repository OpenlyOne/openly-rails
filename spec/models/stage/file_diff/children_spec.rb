# frozen_string_literal: true

RSpec.describe Stage::FileDiff::Children, type: :model do
  subject(:diff_children) do
    Stage::FileDiff::Children.new(project: project, parent_id: parent_id)
  end
  let(:project)   { nil }
  let(:parent_id) { nil }

  describe '#as_diffs' do
    subject         { diff_children.as_diffs }
    let(:children)  { [c1, c2, c3, c4] }
    let(:c1)        { instance_double FileResource::Snapshot }
    let(:c2)        { instance_double FileResource::Snapshot }
    let(:c3)        { instance_double FileResource::Snapshot }
    let(:c4)        { instance_double FileResource::Snapshot }

    before do
      allow(diff_children)
        .to receive(:children_of_staged_and_committed_file).and_return children
      allow(c1).to receive(:file_resource_id).and_return 1
      allow(c2).to receive(:file_resource_id).and_return 2
      allow(c3).to receive(:file_resource_id).and_return 3
      allow(c4).to receive(:file_resource_id).and_return 1

      allow(diff_children)
        .to receive(:children_snapshots_to_diff).with([c1, c4]).and_return 'd1'
      allow(diff_children)
        .to receive(:children_snapshots_to_diff).with([c2]).and_return 'd2'
      allow(diff_children)
        .to receive(:children_snapshots_to_diff).with([c3]).and_return 'd3'
      allow(diff_children).to receive(:remove_children_moved_to_another_folder!)
      allow(diff_children).to receive(:update_children_moved_into_this_folder!)
    end

    it { is_expected.to eq %w[d1 d2 d3] }

    it 'calls #remove_children_moved_to_another_folder!' do
      expect(diff_children)
        .to receive(:remove_children_moved_to_another_folder!)
        .with(%w[d1 d2 d3])
      subject
    end

    it 'calls #update_children_moved_into_this_folder!' do
      expect(diff_children)
        .to receive(:update_children_moved_into_this_folder!)
        .with(%w[d1 d2 d3])
      subject
    end
  end

  describe '#remove_children_moved_to_another_folder!(children)' do
    subject do
      diff_children.send :remove_children_moved_to_another_folder!, children
    end
    let(:children)  { [c1, c2, c3] }
    let(:c1)        { instance_double Stage::FileDiff }
    let(:c2)        { instance_double Stage::FileDiff }
    let(:c3)        { instance_double Stage::FileDiff }
    let(:project)   { instance_double Project }

    before do
      allow(c1).to receive(:deleted?).and_return false
      allow(c1).to receive(:file_resource_id).and_return 1
      allow(c2).to receive(:deleted?).and_return true
      allow(c2).to receive(:file_resource_id).and_return 2
      allow(c3).to receive(:deleted?).and_return true
      allow(c3).to receive(:file_resource_id).and_return 3

      snapshot_class = class_double FileResource::Snapshot
      query = class_double FileResource::Snapshot
      allow(project)
        .to receive(:non_root_file_snapshots_in_stage).and_return snapshot_class
      allow(snapshot_class)
        .to receive(:where).with(file_resource: [2, 3]).and_return query
      allow(query).to receive(:pluck).with(:file_resource_id).and_return [2]
    end

    it 'removes c2 from children' do
      subject
      expect(children).to eq [c1, c3]
    end
  end

  describe '#update_children_moved_into_this_folder!(children)' do
    subject do
      diff_children.send :update_children_moved_into_this_folder!, children
    end
    let(:children)  { [c1, c2, c3] }
    let(:c1)        { instance_double Stage::FileDiff }
    let(:c2)        { instance_double Stage::FileDiff }
    let(:c3)        { instance_double Stage::FileDiff }
    let(:project)   { instance_double Project }
    let(:r3)        { instance_double Revision }
    let(:s2)        { instance_double FileResource::Snapshot }

    before do
      allow(c1).to receive(:added?).and_return false
      allow(c1).to receive(:file_resource_id).and_return 1
      allow(c1).to receive(:committed_snapshot=).with(nil)
      allow(c2).to receive(:added?).and_return true
      allow(c2).to receive(:file_resource_id).and_return 2
      allow(c2).to receive(:committed_snapshot=).with(s2)
      allow(c3).to receive(:added?).and_return true
      allow(c3).to receive(:file_resource_id).and_return 3
      allow(c3).to receive(:committed_snapshot=).with(nil)

      snapshot_class = class_double FileResource::Snapshot
      allow(project)
        .to receive(:revisions).and_return ['r1', 'r2', r3]
      allow(r3).to receive(:committed_file_snapshots).and_return snapshot_class
      allow(snapshot_class)
        .to receive(:where).with(file_resource: [2, 3]).and_return [s2]
      allow(s2).to receive(:file_resource_id).and_return 2
    end

    it 'keeps children intact' do
      expect { subject }.not_to(change { children })
    end

    it 'updates c2 from children' do
      expect(c2).to receive(:committed_snapshot=).with(s2)
      subject
    end
  end
end
