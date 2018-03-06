# frozen_string_literal: true

RSpec.describe Stage::FileDiff::Children, type: :model do
  describe '#as_diffs' do
    subject(:diffs) { children.as_diffs }
    let(:children) do
      Stage::FileDiff::Children.new(project: project, parent_id: folder.id)
    end

    let(:project) { create :project }
    let(:root)    { create :file_resource }
    let(:folder) { create :file_resource, parent: root }
    let(:to_ignore) { create_list :file_resource, 2, parent: root }
    let(:no_change) { create_list :file_resource, 2, parent: folder }
    let(:to_add) { create_list :file_resource, 2, parent: folder }
    let(:to_delete) { create_list :file_resource, 2, parent: folder }
    let(:to_move_out) { create_list :file_resource, 2, parent: folder }
    let(:to_move_in) { create_list :file_resource, 2, parent: root }
    let(:to_rename) { create_list :file_resource, 2, parent: folder }
    let(:to_modify) { create_list :file_resource, 2, parent: folder }
    let(:init_all) do
      [folder, no_change, to_delete, to_move_out, to_move_in, to_rename,
       to_modify, to_ignore]
    end
    let(:create_revision) do
      r = create(:revision, project: project)
      r.commit_all_files_staged_in_project
      r.update(is_published: true, title: 'origin revision')
    end

    before do
      # add all to stage
      project.root_folder = root
      init_all

      # create revision
      create_revision

      # make changes
      to_add
      to_delete.each { |f| f.update(is_deleted: true) }
      to_move_out.each { |f| f.update(parent_id: folder.parent_id) }
      to_move_in.each { |f| f.update(parent_id: folder.id) }
      to_rename.each { |f| f.update(name: 'new-name') }
      to_modify.each { |f| f.update(content_version: 'new') }
    end

    it 'has the right children' do
      expect(diffs.length).to eq 12

      expect(diffs.reject(&:changed?).map(&:file_resource_id))
        .to contain_exactly(*no_change.map(&:id))

      expect(diffs.select(&:added?).map(&:file_resource_id))
        .to contain_exactly(*to_add.map(&:id))

      expect(diffs.select(&:deleted?).map(&:file_resource_id))
        .to contain_exactly(*to_delete.map(&:id))

      expect(diffs.select(&:moved?).map(&:file_resource_id))
        .to contain_exactly(*to_move_in.map(&:id))

      expect(diffs.select(&:renamed?).map(&:file_resource_id))
        .to contain_exactly(*to_rename.map(&:id))

      expect(diffs.select(&:modified?).map(&:file_resource_id))
        .to contain_exactly(*to_modify.map(&:id))
    end

    it 'does not have children that belong to other folders' do
      expect(diffs.map(&:file_resource_id))
        .not_to include(*to_move_out.map(&:id))
      expect(diffs.map(&:file_resource_id))
        .not_to include(*to_ignore.map(&:id))
    end

    context 'when there is no published revision' do
      let(:create_revision) do
        r = create(:revision, project: project)
        r.commit_all_files_staged_in_project
      end
      let(:child_files) do
        no_change + to_add + to_move_in + to_rename + to_modify
      end

      it 'has all diffs as added' do
        expect(diffs).to be_all(&:added?)
        expect(diffs.map(&:file_resource_id))
          .to contain_exactly(*child_files.map(&:id))
      end
    end
  end
end
