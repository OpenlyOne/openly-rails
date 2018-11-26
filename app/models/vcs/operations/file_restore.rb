# frozen_string_literal: true

module VCS
  module Operations
    # Restore a file version to the provided target branch
    # rubocop:disable Metrics/ClassLength
    class FileRestore
      delegate :addition?, :deletion?, :modification?, :rename?, :movement?,
               to: :diff, prefix: :perform

      # Initialize a new instance of FileRestore and prepare for restoring the
      # provided version to the provided target_branch
      def initialize(version:, file_id: nil, target_branch:)
        self.version = version
        self.file_id = file_id || version.file_id
        self.target_branch = target_branch
      end

      # Perform the restoration of the version
      def restore
        # Do nothing if there is no diff!
        return unless diff.change?
        raise 'This version cannot be restored' unless restorable?

        perform_restoration

        # Update in stage
        file_in_branch.update(
          version_attributes.merge(remote_file_id: remote_file_id,
                                   content_version: content_version,
                                   is_deleted: version.nil?)
        )
      end

      # The version can only be restored if a backup is present OR
      # if the restoration is only affecting location and name
      def restorable?
        # Deletion is always possible
        return true if perform_deletion?

        # Otherwise, version must be present AND...
        version.present? &&
          # version must be folder OR have backup OR diff is not
          # addition/modification (but movement/rename)
          (version.folder? ||
          version.backup.present? ||
          (!perform_addition? && !perform_modification?))
      end

      private

      attr_accessor :version, :target_branch, :file_id
      attr_writer :remote_file_id

      # Create remote file from backup copy
      def add_file
        replacement = version.folder? ? create_folder : duplicate_file
        self.remote_file_id = replacement.id

        # Create a new remote content record that points at the same content
        # version as the version that we're restoring. Essentially, we're
        # mapping the new remote file's content to the existing local content,
        # saying that they're one and the same.
        # TODO: Add helper method for creating a new remote version of content
        version.content.remote_contents.create!(
          repository: version.repository,
          remote_file_id: remote_file_id,
          remote_content_version_id: replacement.content_version
        )
      end

      # Duplicate or create file depending on whether this is a folder or not
      def duplicate_file
        file_sync_class.new(version.backup.remote_file_id).duplicate(
          name: version.name,
          parent_id: parent_in_branch.remote_file_id
        )
      end

      def create_folder
        file_sync_class.create(
          name: version.name,
          parent_id: parent_in_branch.remote_file_id,
          mime_type: version.mime_type
        )
      end

      # Delete file by removing it from its parent folder
      # Calling the delete API endpoint results in insufficient permission
      # error unless the action is performed by the file owner.
      def remove_file
        file_in_branch.remote.relocate(
          to: nil,
          from: file_in_branch.parent_in_branch.remote_file_id
        )
      end

      # Create remote file from backup copy and delete current file
      def replace_file
        add_file
        remove_file
      end

      # Move remote file
      def relocate_file
        file_in_branch.remote.relocate(
          to: parent_in_branch.remote_file_id,
          from: file_in_branch.parent_in_branch.remote_file_id
        )
      end

      # Rename remote file
      def rename_file
        file_in_branch.remote.rename(version.name)
      end

      # Calculate the diff of new version vs current version
      def diff
        @diff ||=
          VCS::FileDiff.new(
            new_version: version,
            old_version: file_in_branch&.current_version
          )
      end

      def remote_file_id
        @remote_file_id ||= file_in_branch.remote_file_id
      end

      def content
        @content ||= version&.content
      end

      def content_version
        @content_version ||=
          VCS::RemoteContent.find_by(
            repository: version&.repository,
            content_id: content&.id,
            remote_file_id: remote_file_id
          )&.remote_content_version_id
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

      def parent_in_branch_of_version_to_restore
        target_branch
          .files
          .joins(:current_version)
          .find_by(file_id: version.parent_id)
      end

      def parent_in_branch
        return nil unless version.present?

        parent_in_branch_of_version_to_restore || target_branch.root
      end

      def version_attributes
        {
          name: version&.name,
          mime_type: version&.mime_type,
          parent_in_branch: parent_in_branch,
          thumbnail_id: version&.thumbnail_id
        }
      end

      # Identify the FileInBranch to modify with the provided version
      def file_in_branch
        @file_in_branch ||=
          target_branch
          .files
          .find_or_create_by(file_id: file_id)
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
