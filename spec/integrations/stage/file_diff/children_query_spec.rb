# frozen_string_literal: true

require 'integrations/shared_contexts/skip_project_archive_setup'

RSpec.describe Stage::FileDiff::ChildrenQuery, type: :model do
  include_context 'skip project archive setup'

  subject(:diffs) do
    described_class.new(project: project, parent_id: folder.id)
  end

  let(:project)     { create :project }
  let(:root)        { create :file_resource }
  let(:folder)      { create :file_resource, parent: root }
  let(:to_ignore)   { create_list :file_resource, 2, parent: root }
  let(:no_change)   { create_list :file_resource, 2, parent: folder }
  let(:to_add)      { create_list :file_resource, 2, parent: folder }
  let(:to_delete)   { create_list :file_resource, 2, parent: folder }
  let(:to_move_out) { create_list :file_resource, 2, parent: folder }
  let(:to_move_in)  { create_list :file_resource, 2, parent: root }
  let(:to_rename)   { create_list :file_resource, 2, parent: folder }
  let(:to_modify)   { create_list :file_resource, 2, parent: folder }
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
    expect(diffs.count).to eq 12

    expect(diffs.reject(&:change?).map(&:file_resource_id))
      .to contain_exactly(*no_change.map(&:id))

    expect(diffs.select(&:addition?).map(&:file_resource_id))
      .to contain_exactly(*to_add.map(&:id))

    expect(diffs.select(&:deletion?).map(&:file_resource_id))
      .to contain_exactly(*to_delete.map(&:id))

    expect(diffs.select(&:movement?).map(&:file_resource_id))
      .to contain_exactly(*to_move_in.map(&:id))

    expect(diffs.select(&:rename?).map(&:file_resource_id))
      .to contain_exactly(*to_rename.map(&:id))

    expect(diffs.select(&:modification?).map(&:file_resource_id))
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
      expect(diffs).to be_all(&:addition?)
      expect(diffs.map(&:file_resource_id))
        .to contain_exactly(*child_files.map(&:id))
    end
  end
end
