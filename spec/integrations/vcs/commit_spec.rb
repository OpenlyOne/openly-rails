# frozen_string_literal: true

require 'integrations/shared_contexts/skip_project_archive_setup'

RSpec.describe VCS::Commit, type: :model do
  include_context 'skip project archive setup'

  subject(:commit) { build(:vcs_commit) }

  describe 'notifications' do
    subject(:commit) do
      create(:vcs_commit, :drafted, branch: branch, author: author)
    end
    let(:branch)        { project.master_branch }
    let(:project) { create(:project, :skip_archive_setup, :with_repository) }
    let(:owner)         { project.owner }
    let(:collaborator1) { create :user }
    let(:collaborator2) { create :user }
    let(:collaborator3) { create :user }
    let(:author)        { collaborator1 }
    let(:publish)       { true }

    before do
      project.collaborators << [collaborator1, collaborator2, collaborator3]
      commit.update(is_published: publish, title: 'Revision')
    end

    it 'creates a notification for owner + collaborators, except the author' do
      expect(Notification.count).to eq 3
      expect(Notification.all.map(&:target))
        .to match_array [owner, collaborator2, collaborator3].map(&:account)
      expect(Notification.all.map(&:notifier).uniq)
        .to contain_exactly author
      expect(Notification.all.map(&:notifiable).uniq)
        .to contain_exactly commit
    end

    it 'sends an email to each notification recipient' do
      expect(ActionMailer::Base.deliveries.map(&:to).flatten)
        .to match_array(
          [owner, collaborator2, collaborator3].map(&:account).map(&:email)
        )
    end

    context 'when commit is not published' do
      let(:publish) { false }

      it 'does not create notifications' do
        expect(Notification).to be_none
      end
    end

    context 'when commit is destroyed' do
      it 'deletes all notifications' do
        expect { commit.destroy }.to change(Notification, :count).to(0)
      end
    end
  end

  describe 'validation: parent must belong to same project' do
    let(:parent)        { create(:vcs_commit) }
    before              { commit.parent = parent }

    context 'when parent commit belongs to different branch' do
      before  { commit.branch = create(:vcs_branch) }
      it      { is_expected.to be_invalid }
    end

    context 'when parent commit belongs to same branch' do
      before  { commit.branch = parent.branch }
      it      { is_expected.to be_valid }
    end
  end

  describe 'validation: can have only one origin commit per branch' do
    subject(:new_origin)  { build(:vcs_commit, branch: branch) }
    let(:branch)          { create(:vcs_branch) }

    context 'when published origin commit exists in branch' do
      let!(:existing_origin) { create :vcs_commit, :published, branch: branch }
      it                     { is_expected.to be_invalid }
    end

    context 'when origin commit in branch is not published' do
      let!(:existing_origin) { create :vcs_commit, branch: branch }
      it                     { is_expected.to be_valid }
    end

    context 'when origin commit exists in another branch' do
      let!(:existing_origin) do
        create :vcs_commit, :published, branch: other_branch
      end
      let(:other_branch)  { create(:vcs_branch) }

      it { is_expected.to be_valid }
    end
  end

  describe 'validation: can have only one commit with parent' do
    subject(:commit)    { build(:vcs_commit, parent: parent, branch: branch) }
    let(:parent)        { create(:vcs_commit, branch: branch) }
    let(:branch)        { create(:vcs_branch) }

    context 'when commit with same parent exists' do
      let!(:existing) do
        create :vcs_commit, :published, parent: parent, branch: branch
      end

      it                { is_expected.to be_invalid }
    end

    context 'when commit with same parent is not published' do
      let!(:existing) { create :vcs_commit, parent: parent }
      it              { is_expected.to be_valid }
    end

    context 'when commit with same parent does not exist' do
      let!(:existing) { create :vcs_commit, :with_parent }
      it              { is_expected.to be_valid }
    end
  end

  describe 'callback: apply_selected_changes' do
    let(:apply_changes) { commit.publish(title: 'new commit') }
    let(:author)    { create(:user) }
    let(:branch)    { create(:vcs_branch) }
    let(:origin)    { branch.commits.create_draft_and_commit_files!(author) }
    let(:commit)    { branch.commits.create_draft_and_commit_files!(author) }
    let(:parent)    { create :vcs_staged_file, :folder, branch: branch }
    let(:update)    { create :vcs_staged_file, branch: branch }
    let(:deletion)  { create :vcs_staged_file, branch: branch }
    let(:addition)  { create :vcs_staged_file, branch: branch }

    before do
      parent && update && deletion
      origin.publish(title: 'origin')

      update.update(
        name: 'new-name',
        content_version: 5,
        file_record_parent: parent.file_record
      )
      deletion.update(is_deleted: true)
      addition
      commit

      action
      apply_changes
    end

    context 'when all changes are unselected and applied' do
      let(:action) { commit.file_changes.each(&:unselect!) }

      it 'has the same committed files as previous commit' do
        files_in_commit   = commit.committed_snapshot_ids
        files_in_origin   = origin.committed_snapshot_ids
        expect(files_in_commit).to match_array files_in_origin
      end

      it 'has no file diffs' do
        expect(commit.file_diffs.reload).to be_empty
      end
    end

    context 'when addition is unselected and applied' do
      let(:action) { commit.file_changes.find(&:addition?).unselect! }
      it { expect(commit.file_changes).not_to be_any(&:addition?) }
    end

    context 'when movement is unselected and applied' do
      let(:action) { commit.file_changes.find(&:movement?).unselect! }
      it { expect(commit.file_changes).not_to be_any(&:movement?) }
    end

    context 'when rename is unselected and applied' do
      let(:action) { commit.file_changes.find(&:rename?).unselect! }
      it { expect(commit.file_changes).not_to be_any(&:rename?) }
    end

    context 'when modification is unselected and applied' do
      let(:action) { commit.file_changes.find(&:modification?).unselect! }
      it { expect(commit.file_changes).not_to be_any(&:modification?) }
    end

    context 'when deletion is unselected and applied' do
      let(:action) { commit.file_changes.find(&:deletion?).unselect! }
      it { expect(commit.file_changes).not_to be_any(&:deletion?) }
    end
  end

  describe 'association extension: committed_files#in_folder(folder)' do
    subject(:method) do
      commit.committed_files.in_folder(folder).map(&:file_snapshot)
    end

    let(:commit)    { create :vcs_commit, branch: branch }
    let(:branch)    { create(:vcs_branch) }
    let(:folder)    { create :vcs_file_snapshot, :folder }
    let(:parent)    { folder }
    let!(:f1)       { create :vcs_file_snapshot, parent: parent }
    let!(:f2)       { create :vcs_file_snapshot, parent: parent }
    let!(:f3)       { create :vcs_file_snapshot, parent: parent }

    before do
      [f1, f2, f3].each do |snapshot|
        create :vcs_committed_file, commit: commit, file_snapshot: snapshot
      end
      commit.update(is_published: true, title: 'origin')
    end

    it 'returns files in folder' do
      is_expected.to contain_exactly(f1, f2, f3)
    end

    context 'when folder has no children' do
      let(:parent) { create(:vcs_file_snapshot, :folder) }

      it { is_expected.to be_empty }
    end

    context 'when folder does not exist' do
      let(:folder) { build(:vcs_file_snapshot, :folder) }
      let(:parent) { create(:vcs_file_snapshot, :folder) }

      it { is_expected.to be_empty }
    end
  end

  describe '#commit_all_files_staged_in_branch' do
    subject(:committed_files) { commit.committed_files }
    let(:commit)              { create :vcs_commit }
    let(:branch)              { commit.branch }
    let!(:staged_files) { create_list :vcs_staged_file, 10, branch: branch }
    let!(:root_folder)  { create :vcs_staged_file, :root, branch: branch }
    let(:commit_files) { commit.commit_all_files_staged_in_branch }

    # Create staged files in another branch
    # This is to ensure that committing affects only the files staged for the
    # specific branch we are staging for
    before do
      other_branch = create(:vcs_branch)
      create_list(:vcs_staged_file, 10, branch: other_branch)
    end

    before { commit_files }

    it { expect(subject.count).to eq 10 }

    it 'has the correct file snapshot IDs' do
      expect(committed_files.map(&:file_snapshot_id))
        .to match_array(staged_files.map(&:current_snapshot_id))
    end

    it 'does not commit the root file' do
      is_expected.not_to be_exists(file_snapshot: root_folder.current_snapshot)
    end

    context 'when no files are staged' do
      let(:staged_files) { [] }

      it { is_expected.to be_none }
    end

    context 'when a staged file has current_snapshot=nil' do
      let(:staged_files)                  { [file_without_current_snapshot] }
      let(:file_without_current_snapshot) { create :vcs_staged_file, :deleted }

      it 'does not commit that file' do
        is_expected.to be_none
      end
    end
  end
end
