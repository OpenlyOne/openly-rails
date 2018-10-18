# frozen_string_literal: true

require 'integrations/shared_contexts/skip_project_archive_setup'

RSpec.describe Revision, type: :model do
  include_context 'skip project archive setup'

  subject(:revision) { build(:revision) }

  describe 'notifications' do
    subject(:revision) do
      create(:revision, :drafted, project: project, author: author)
    end
    let(:project)       { create :project }
    let(:owner)         { project.owner }
    let(:collaborator1) { create :user }
    let(:collaborator2) { create :user }
    let(:collaborator3) { create :user }
    let(:author)        { collaborator1 }
    let(:publish)       { true }

    before do
      project.collaborators << [collaborator1, collaborator2, collaborator3]
      revision.update(is_published: publish, title: 'Revision')
    end

    it 'creates a notification for owner + collaborators, except the author' do
      expect(Notification.count).to eq 3
      expect(Notification.all.map(&:target))
        .to match_array [owner, collaborator2, collaborator3].map(&:account)
      expect(Notification.all.map(&:notifier).uniq)
        .to contain_exactly author
      expect(Notification.all.map(&:notifiable).uniq)
        .to contain_exactly revision
    end

    it 'sends an email to each notification recipient' do
      expect(ActionMailer::Base.deliveries.map(&:to).flatten)
        .to match_array(
          [owner, collaborator2, collaborator3].map(&:account).map(&:email)
        )
    end

    context 'when revision is not published' do
      let(:publish) { false }

      it 'does not create notifications' do
        expect(Notification).to be_none
      end
    end

    context 'when revision is destroyed' do
      it 'deletes all notifications' do
        expect { revision.destroy }.to change(Notification, :count).to(0)
      end
    end
  end

  describe 'validation: parent must belong to same project' do
    let(:parent)        { create(:revision) }
    before              { revision.parent = parent }

    context 'when parent revision belongs to different project' do
      before  { revision.project = create(:project) }
      it      { is_expected.to be_invalid }
    end

    context 'when parent revision belongs to same project' do
      before  { revision.project = parent.project }
      it      { is_expected.to be_valid }
    end
  end

  describe 'validation: can have only one origin revision per project' do
    subject(:new_origin) { build(:revision, project: project) }
    let(:project)        { create(:project) }

    context 'when published origin revision exists in project' do
      let!(:existing_origin) { create :revision, :published, project: project }
      it                     { is_expected.to be_invalid }
    end

    context 'when origin revision in project is not published' do
      let!(:existing_origin) { create :revision, project: project }
      it                     { is_expected.to be_valid }
    end

    context 'when origin revision exists in another project' do
      let!(:existing_origin) { create :revision, :published }
      it { is_expected.to be_valid }
    end
  end

  describe 'validation: can have only one revision with parent' do
    subject(:revision)  { build(:revision, parent: parent) }
    let(:parent)        { create(:revision) }

    context 'when revision with same parent exists' do
      let!(:existing) { create :revision, :published, parent: parent }
      it              { is_expected.to be_invalid }
    end

    context 'when revision with same parent is not published' do
      let!(:existing) { create :revision, parent: parent }
      it              { is_expected.to be_valid }
    end

    context 'when revision with same parent does not exist' do
      let!(:existing) { create :revision, :with_parent }
      it              { is_expected.to be_valid }
    end
  end

  describe 'callback: apply_selected_changes' do
    let(:apply_changes) { revision.publish(title: 'new revision') }
    let(:project)   { create :project }
    let(:author)    { project.owner }
    let(:origin)    { project.revisions.create_draft_and_commit_files!(author) }
    let(:revision)  { project.revisions.create_draft_and_commit_files!(author) }
    let(:parent)    { create :file_resource, :folder }
    let(:update)    { create :file_resource }
    let(:deletion)  { create :file_resource }
    let(:addition)  { create :file_resource }

    before do
      project.file_resources_in_stage << [parent, update, deletion]
      origin.publish(title: 'origin')

      update.update(name: 'new-name', content_version: 5, parent: parent)
      deletion.update(is_deleted: true)
      project.file_resources_in_stage << [addition]
      revision

      action
      apply_changes
    end

    context 'when all changes are unselected and applied' do
      let(:action) { revision.file_changes.each(&:unselect!) }

      it 'has the same committed files as previous revision' do
        file_keys         = %i[file_resource_id file_resource_snapshot_id]
        files_in_revision = revision.committed_files.pluck(*file_keys)
        files_in_origin   = origin.committed_files.pluck(*file_keys)
        expect(files_in_revision).to match_array files_in_origin
      end

      it 'has no file diffs' do
        expect(revision.file_diffs.reload).to be_empty
      end
    end

    context 'when addition is unselected and applied' do
      let(:action) { revision.file_changes.find(&:addition?).unselect! }
      it { expect(revision.file_changes).not_to be_any(&:addition?) }
    end

    context 'when movement is unselected and applied' do
      let(:action) { revision.file_changes.find(&:movement?).unselect! }
      it { expect(revision.file_changes).not_to be_any(&:movement?) }
    end

    context 'when rename is unselected and applied' do
      let(:action) { revision.file_changes.find(&:rename?).unselect! }
      it { expect(revision.file_changes).not_to be_any(&:rename?) }
    end

    context 'when modification is unselected and applied' do
      let(:action) { revision.file_changes.find(&:modification?).unselect! }
      it { expect(revision.file_changes).not_to be_any(&:modification?) }
    end

    context 'when deletion is unselected and applied' do
      let(:action) { revision.file_changes.find(&:deletion?).unselect! }
      it { expect(revision.file_changes).not_to be_any(&:deletion?) }
    end
  end

  describe '#commit_all_files_staged_in_project' do
    subject(:committed_files)     { revision.committed_files }
    let(:revision)                { create :revision }
    let(:project)                 { revision.project }
    let(:file_resources_in_stage) { create_list :file_resource, 10 }
    let(:root_file)               { create :file_resource }
    let(:commit_files) { revision.commit_all_files_staged_in_project }

    # Create staged files in another project
    # This is to ensure that committing affects only the files staged for the
    # specific project we are staging for
    before do
      other_project = create(:project)
      other_project.file_resources_in_stage = create_list(:file_resource, 10)
    end

    before { project.file_resources_in_stage = file_resources_in_stage }
    before { project.create_staged_root_folder(file_resource: root_file) }
    before { commit_files }

    it { expect(subject.count).to eq 10 }

    it 'has the correct file resource IDs & file resource snapshot IDs' do
      committed =
        subject.map { |f| [f.file_resource_id, f.file_resource_snapshot_id] }
      staged = file_resources_in_stage.map { |f| [f.id, f.current_snapshot_id] }
      expect(committed).to contain_exactly(*staged)
    end

    it 'does not commit the root file' do
      is_expected.not_to be_exists(file_resource: root_file)
    end

    context 'when no files are staged' do
      let(:file_resources_in_stage) { [] }

      it { is_expected.to be_none }
    end

    context 'when a file resource with current_snapshot=nil is in stage' do
      let(:file_resources_in_stage)       { [file_without_current_snapshot] }
      let(:file_without_current_snapshot) { create :file_resource, :deleted }

      it 'does not commit that file' do
        is_expected
          .not_to be_exists(file_resource: file_without_current_snapshot)
      end
    end
  end
end
