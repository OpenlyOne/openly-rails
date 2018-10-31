# frozen_string_literal: true

module VCS
  module Operations
    # Restore a file snapshot to the provided target branch
    class FileRestore
      # Initialize a new instance of FileRestore and prepare for restoring the
      # provided snapshot to the provided target_branch
      def initialize(snapshot:, target_branch:)
        self.snapshot = snapshot
        self.target_branch = target_branch
      end

      # Perform the restoration of the snapshot
      def restore
        # Do nothing if there is no diff!
        return unless diff.change?
        raise 'This snapshot cannot be restored' unless restorable?

        perform_restoration

        # Update in stage
        staged_file.update(
          snapshot_attributes.merge(external_id: external_id, is_deleted: false)
        )
      end

      # The snapshot can only be restored if a backup is present OR
      # if the restoration is only affecting location and name
      def restorable?
        # Snapshot must be present AND...
        snapshot.present? &&
          # snapshot must be folder OR have backup OR diff is not
          # addition/modification (but movement/rename)
          (snapshot.folder? ||
          snapshot.backup.present? ||
          (!diff.addition? && !diff.modification?))
      end

      private

      attr_accessor :snapshot, :target_branch
      attr_writer :external_id

      # Create remote file from backup copy
      def add_file
        replacement = snapshot.folder? ? create_folder : duplicate_file
        self.external_id = replacement.id
      end

      # Duplicate or create file depending on whether this is a folder or not
      def duplicate_file
        file_sync_class.new(snapshot.backup.external_id).duplicate(
          name: snapshot.name,
          parent_id: staged_parent.external_id
        )
      end

      def create_folder
        file_sync_class.create(
          name: snapshot.name,
          parent_id: staged_parent.external_id,
          mime_type: snapshot.mime_type
        )
      end

      # Create remote file from backup copy and delete current file
      def replace_file
        add_file

        # Delete file by removing it from its parent folder
        # Calling the delete API endpoint results in insufficient permission
        # error unless the action is performed by the file owner.
        file_sync_class
          .new(staged_file.external_id)
          .relocate(to: nil, from: staged_file.parent.external_id)
      end

      # Move remote file
      def relocate_file
        file_sync_class
          .new(staged_file.external_id)
          .relocate(
            to: staged_parent.external_id,
            from: staged_file.parent.external_id
          )
      end

      # Rename remote file
      def rename_file
        file_sync_class.new(staged_file.external_id).rename(snapshot.name)
      end

      # Calculate the diff of new snapshot vs currently staged snapshot
      def diff
        @diff ||=
          VCS::FileDiff.new(
            new_snapshot: snapshot,
            old_snapshot: staged_file&.current_snapshot
          )
      end

      def external_id
        @external_id ||= staged_file.external_id
      end

      def file_sync_class
        Providers::GoogleDrive::FileSync
      end

      def perform_restoration
        # Add file
        return add_file if diff.addition?

        # # Replace file
        return replace_file if diff.modification?

        # # Move/rename file
        relocate_file if diff.movement?
        rename_file if diff.rename?
      end

      def staged_parent_of_snapshot_to_restore
        target_branch
          .staged_files
          .joins(:current_snapshot)
          .find_by(file_record_id: snapshot.file_record_parent_id)
      end

      def staged_parent
        staged_parent_of_snapshot_to_restore || target_branch.root
      end

      def snapshot_attributes
        snapshot
          .attributes
          .symbolize_keys
          .slice(:name, :content_version, :mime_type)
          .merge(parent: staged_parent)
      end

      # Identify the StagedFile to modify with the provided snapshot
      def staged_file
        @staged_file ||=
          target_branch
          .staged_files
          .find_by(file_record_id: snapshot.file_record_id)
      end
    end
  end
end
