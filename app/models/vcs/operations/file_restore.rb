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
        file_in_branch.update(
          snapshot_attributes.merge(remote_file_id: remote_file_id,
                                    content_version: content_version,
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
      attr_writer :remote_file_id, :content_version

      # Create remote file from backup copy
      def add_file
        replacement = snapshot.folder? ? create_folder : duplicate_file
        self.remote_file_id = replacement.id
        self.content_version = replacement.content_version

        # Create a new remote content record that points at the same content
        # version as the snapshot that we're restoring. Essentially, we're
        # mapping the new remote file's content to the existing local content,
        # saying that they're one and the same.
        # TODO: Add helper method for creating a new remote version of content
        snapshot.content.remote_contents.create!(
          repository: snapshot.repository,
          remote_file_id: remote_file_id,
          remote_content_version_id: content_version
        )
      end

      # Duplicate or create file depending on whether this is a folder or not
      def duplicate_file
        file_sync_class.new(snapshot.backup.remote_file_id).duplicate(
          name: snapshot.name,
          parent_id: parent_in_branch.remote_file_id
        )
      end

      def create_folder
        file_sync_class.create(
          name: snapshot.name,
          parent_id: parent_in_branch.remote_file_id,
          mime_type: snapshot.mime_type
        )
      end

      # Delete file by removing it from its parent folder
      # Calling the delete API endpoint results in insufficient permission
      # error unless the action is performed by the file owner.
      def remove_file
        file_in_branch
          .remote
          .relocate(to: nil, from: file_in_branch.parent.remote_file_id)
      end

      # Create remote file from backup copy and delete current file
      def replace_file
        add_file
        remove_file
      end

      # Move remote file
      def relocate_file
        file_in_branch
          .remote
          .relocate(
            to: parent_in_branch.remote_file_id,
            from: file_in_branch.parent.remote_file_id
          )
      end

      # Rename remote file
      def rename_file
        file_in_branch.remote.rename(snapshot.name)
      end

      # Calculate the diff of new snapshot vs current snapshot
      def diff
        @diff ||=
          VCS::FileDiff.new(
            new_snapshot: snapshot,
            old_snapshot: file_in_branch&.current_snapshot
          )
      end

      def remote_file_id
        @remote_file_id ||= file_in_branch.remote_file_id
      end

      def content_version
        @content_version ||= snapshot&.content_version
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

      def parent_in_branch_of_snapshot_to_restore
        target_branch
          .files
          .joins(:current_snapshot)
          .find_by(file_record_id: snapshot.file_record_parent_id)
      end

      def parent_in_branch
        return nil unless snapshot.present?

        parent_in_branch_of_snapshot_to_restore || target_branch.root
      end

      def snapshot_attributes
        {
          name: snapshot&.name,
          mime_type: snapshot&.mime_type,
          parent: parent_in_branch,
          thumbnail_id: snapshot&.thumbnail_id
        }
      end

      # Identify the FileInBranch to modify with the provided snapshot
      def file_in_branch
        @file_in_branch ||=
          target_branch
          .files
          .find_by(file_record_id: file_record_id)
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
