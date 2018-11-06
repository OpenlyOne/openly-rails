# frozen_string_literal: true

module VCS
  module Operations
    # Restore a file snapshot to the provided target branch
    # rubocop:disable Metrics/ClassLength
    class FileRestore
      delegate :addition?, :deletion?, :modification?, :rename?, :movement?,
               to: :diff, prefix: :perform

      # Initialize a new instance of FileRestore and prepare for restoring the
      # provided snapshot to the provided target_branch
      def initialize(snapshot:, file_record_id: nil, target_branch:)
        self.snapshot = snapshot
        self.file_record_id = file_record_id || snapshot.file_record_id
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
          snapshot_attributes.merge(external_id: external_id,
                                    is_deleted: snapshot.nil?)
        )
      end

      # The snapshot can only be restored if a backup is present OR
      # if the restoration is only affecting location and name
      def restorable?
        # Deletion is always possible
        return true if perform_deletion?

        # Otherwise, snapshot must be present AND...
        snapshot.present? &&
          # snapshot must be folder OR have backup OR diff is not
          # addition/modification (but movement/rename)
          (snapshot.folder? ||
          snapshot.backup.present? ||
          (!perform_addition? && !perform_modification?))
      end

      private

      attr_accessor :snapshot, :target_branch, :file_record_id
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

      # Delete file by removing it from its parent folder
      # Calling the delete API endpoint results in insufficient permission
      # error unless the action is performed by the file owner.
      def remove_file
        file_sync_class
          .new(staged_file.external_id)
          .relocate(to: nil, from: staged_file.parent.external_id)
      end

      # Create remote file from backup copy and delete current file
      def replace_file
        add_file
        remove_file
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
        return add_file if perform_addition?

        # Remove file
        return remove_file if perform_deletion?

        # # Replace file
        return replace_file if perform_modification?

        # # Move/rename file
        relocate_file if perform_movement?
        rename_file if perform_rename?
      end

      def staged_parent_of_snapshot_to_restore
        target_branch
          .staged_files
          .joins(:current_snapshot)
          .find_by(file_record_id: snapshot.file_record_parent_id)
      end

      def staged_parent
        return nil unless snapshot.present?

        staged_parent_of_snapshot_to_restore || target_branch.root
      end

      def snapshot_attributes
        {
          name: snapshot&.name,
          content_version: snapshot&.content_version,
          mime_type: snapshot&.mime_type,
          parent: staged_parent,
          thumbnail_id: snapshot&.thumbnail_id
        }
      end

      # Identify the StagedFile to modify with the provided snapshot
      def staged_file
        @staged_file ||=
          target_branch
          .staged_files
          .find_by(file_record_id: file_record_id)
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
