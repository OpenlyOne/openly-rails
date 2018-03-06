# frozen_string_literal: true

RSpec.describe Stage::FileDiff::Ancestry, type: :model do
  describe '.for(file_resource_snapshot:, project:)' do
    subject(:ancestors) do
      described_class.for(file_resource_snapshot: snapshot, project: project)
    end

    let(:project)   { create :project }
    let(:root)      { create :file_resource, name: 'r6' }
    let(:parent5)   { create :file_resource, name: 'p5', parent: root }
    let(:parent4)   { create :file_resource, name: 'p4', parent: parent5 }
    let(:parent3)   { create :file_resource, name: 'p3', parent: parent4 }
    let(:parent2)   { create :file_resource, name: 'p2', parent: parent3 }
    let(:parent1)   { create :file_resource, name: 'p1', parent: parent2 }
    let(:child)     { create :file_resource, name: 'c0', parent: parent1 }
    let(:snapshot) do
      Stage::FileDiff
        .find_by!(external_id: child.external_id, project: project)
        .current_or_previous_snapshot
    end

    let(:create_revision) do
      r = create(:revision, project: project)
      r.commit_all_files_staged_in_project
      r.update(is_published: revision_is_published, title: 'origin revision')
    end
    let(:revision_is_published) { true }

    before do
      # add all to stage
      project.root_folder = root
      child # init all files

      # create revision
      create_revision

      # update ancestors
      parent2.update(name: 'updated-p2', parent: parent4)
    end

    it 'has the right ancestors' do
      expect(ancestors.map(&:name)).to eq %w[p1 updated-p2 p4 p5]
      expect(ancestors.map(&:file_resource_id))
        .to eq [parent1, parent2, parent4, parent5].map(&:id)
    end

    context 'when some ancestors are deleted in stage' do
      before do
        [child, parent1, parent2].each do |file|
          file.update(is_deleted: true)
        end
      end

      it 'uses ancestors from last revision' do
        expect(ancestors.map(&:name)).to eq %w[p1 p2 p3 p4 p5]
        expect(ancestors.map(&:file_resource_id))
          .to eq [parent1, parent2, parent3, parent4, parent5].map(&:id)
      end
    end

    context 'when there is no published revision' do
      let(:revision_is_published) { false }

      it 'has the right ancestors' do
        expect(ancestors.map(&:name)).to eq %w[p1 updated-p2 p4 p5]
        expect(ancestors.map(&:file_resource_id))
          .to eq [parent1, parent2, parent4, parent5].map(&:id)
      end
    end
  end
end
