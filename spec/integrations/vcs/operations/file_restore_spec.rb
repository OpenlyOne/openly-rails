# frozen_string_literal: true

RSpec.describe VCS::Operations::FileRestore, type: :model, vcr: true do
  before  { prepare_google_drive_test }
  after   { tear_down_google_drive_test }

  describe '#restore' do
    subject(:file_restore) do
      described_class
        .new(snapshot: snapshot_to_restore, target_branch: root.branch)
    end

    let!(:remote_subfolder) do
      file_sync_class.create(
        name: 'Folder',
        parent_id: google_drive_test_folder_id,
        mime_type: Providers::GoogleDrive::MimeType.folder
      )
    end

    let!(:remote_file) do
      file_sync_class.create(
        name: 'original name',
        parent_id: remote_subfolder.id,
        mime_type: file_mime_type
      )
    end
    let(:file_mime_type) { Providers::GoogleDrive::MimeType.document }

    let(:file_sync_class) { Providers::GoogleDrive::FileSync }

    let!(:project)  { create(:project, owner_account_email: user_acct) }
    let(:user_acct) { ENV['GOOGLE_DRIVE_USER_ACCOUNT'] }

    let!(:root) do
      create :vcs_staged_file, :root,
             external_id: google_drive_test_folder_id,
             branch: project.master_branch
    end

    let!(:subfolder) do
      create :vcs_staged_file, :folder,
             parent: root, external_id: remote_subfolder.id
    end

    let!(:file) do
      build(:vcs_staged_file, external_id: remote_file.id, branch: root.branch)
    end

    let(:file_change) do
      VCS::FileDiff.new(
        new_snapshot: file.current_snapshot,
        old_snapshot: snapshot_before_performing_restoration
      )
    end
    let(:attributes_of_snapshot_to_restore) do
      snapshot_to_restore
        .attributes
        .symbolize_keys
        .slice(:name, :content_version, :file_record, :file_record_parent_id)
    end

    let(:snapshot_before_performing_restoration)  { file.current_snapshot }
    let(:snapshot_to_restore)                     { file.current_snapshot }
    let(:remote_file_after_restore) { file_sync_class.new(file.external_id) }
    let(:parent_of_snapshot_to_restore) do
      root.branch
          .staged_files
          .find_by(file_record_id: snapshot_to_restore.file_record_parent_id)
    end
    let(:expected_parent)           { parent_of_snapshot_to_restore }
    let(:expected_content_version)  { snapshot_to_restore.content_version }
    let(:expected_deletion_status)  { false }
    let(:expected_snapshot_id)      { snapshot_to_restore&.id }

    before do
      # capture the initial snapshot which we will later restore
      file.pull
      snapshot_to_restore

      # perform file actions, such as rename etc. & capture snapshot before
      # restoration
      file_actions
      file.reload
      file.pull
      snapshot_before_performing_restoration

      # perform the restoration
      file_restore.restore
      file.reload
    end

    after do
      expect(file.current_snapshot_id).to eq expected_snapshot_id
      expect(file).to have_attributes(
        file_record_id: file.file_record_id,
        name: snapshot_to_restore&.name,
        file_record_parent_id: expected_parent&.file_record_id,
        content_version: expected_content_version,
        is_deleted: expected_deletion_status,
        thumbnail_id: snapshot_to_restore&.thumbnail_id
      )
      expect(remote_file_after_restore).to have_attributes(
        expected_remote_attributes
      )
    end

    let(:expected_remote_attributes) do
      {
        id: file.external_id,
        name: snapshot_to_restore&.name,
        parent_id: expected_parent&.external_id,
        content_version: expected_content_version
      }
    end

    context "when restoring the file's current snapshot" do
      let(:file_actions) { nil }

      it 'does not make any changes' do
        expect(file_change).not_to be_change
      end
    end

    context 'when file to restore does not exist in stage' do
      let(:file_actions) { remote_file.delete }

      it 'is added' do
        expect(file_change).to be_addition
      end

      context 'when file to restore is folder' do
        let(:file_mime_type) { Providers::GoogleDrive::MimeType.folder }

        it 'is added' do
          expect(file_change).to be_addition
          expect(file.current_snapshot_id).to eq snapshot_to_restore.id
        end
      end
    end

    context 'when file is in a different location than the snapshot was' do
      let(:remote_subfolder2) do
        file_sync_class.create(
          name: 'Subfolder 2',
          parent_id: google_drive_test_folder_id,
          mime_type: Providers::GoogleDrive::MimeType.folder
        )
      end
      let(:subfolder2) do
        create :vcs_staged_file, :folder,
               parent: root, external_id: remote_subfolder2.id
      end
      let(:file_actions) do
        remote_subfolder2
        subfolder2
        remote_file
          .relocate(to: remote_subfolder2.id, from: remote_subfolder.id)
        post_relocation_hook if defined?(post_relocation_hook)
      end

      it 'moves the file' do
        expect(file_change).to be_movement
        expect(file.current_snapshot_id).to eq snapshot_to_restore.id
      end

      context 'when parent of snapshot to restore does not exist' do
        let(:post_relocation_hook) do
          remote_subfolder.delete
          file.reload.tap(&:pull)
          subfolder.reload.pull
        end
        let(:expected_parent) { root }
        let(:expected_snapshot_id) { file.current_snapshot_id }

        it 'moves snapshot to home folder' do
          expect(file_change).to be_movement
        end
      end
    end

    context 'when file title differs from snapshot title' do
      let(:file_actions) { remote_file.rename('new name') }

      it 'renames the file' do
        expect(file_change).to be_rename
        expect(file.current_snapshot_id).to eq snapshot_to_restore.id
      end
    end

    context 'when file content differs from snapshot content' do
      let(:file_actions) { remote_file.update_content('new content') }
      let(:expected_content_version) do
        remote_file_after_restore.content_version
      end

      it 'is modifies the file' do
        expect(file_change).to be_modification
        expect(file.external_id).not_to eq remote_file.id
        expect(file.current_snapshot_id).to eq snapshot_to_restore.id
      end
    end

    context 'when restoring a snapshot of nil' do
      subject(:file_restore) do
        described_class
          .new(snapshot: snapshot_to_restore,
               file_record_id: file.file_record_id,
               target_branch: root.branch)
      end
      let(:file_actions)              { nil }
      let(:snapshot_to_restore)       { nil }
      let(:expected_parent)           { nil }
      let(:expected_content_version)  { nil }
      let(:expected_deletion_status)  { true }

      # TODO: Refactor. Since we're just relocating the file, it remains
      # accessible and name and content version do not change. THat's why we're
      # doing the manual override here.
      let(:expected_remote_attributes) do
        {
          id: file.external_id,
          parent_id: expected_parent&.external_id
        }
      end

      it 'deletes the file' do
        expect(file_change).to be_deletion
      end
    end
  end
end
