# frozen_string_literal: true

module VCS
  module Operations
    # Backup a file in branch
    class FileBackup
      attr_accessor :file_in_branch, :remote_backup

      delegate :repository, to: :file_in_branch, allow_nil: true
      delegate :archive, to: :repository, allow_nil: true

      # Create a backup for the provided file in branch
      def self.backup(file_in_branch)
        new(file_in_branch).tap(&:perform_backup)
      end

      # Initialize a new instance of FileBackup
      def initialize(file_in_branch)
        self.file_in_branch = file_in_branch
      end

      # Has this file in branch already been backed up?
      def backed_up?
        VCS::FileBackup.exists?(file_version: file_version)
      end

      # Capture a backup of the file in branch and store in archive
      def perform_backup
        # abort process if already exists OR no archive OR no file version
        return false if backed_up? || archive.nil? || file_version.nil?

        create_remote_backup

        # abort process if creating the remote was not successful
        return false if remote_backup.nil?

        store_backup_record
      end

      private

      # Creates a backup of the remote and stores it in the remote archive
      def create_remote_backup
        self.remote_backup =
          file_in_branch.remote.duplicate(
            name: file_in_branch.name,
            parent_id: archive.remote_file_id
          )
      # TODO: Rescue should happen within #duplicate!
      rescue StandardError
        false
      end

      # The current version of the file in branch
      def file_version
        file_in_branch&.current_version
      end

      # Locally stores a reference to the remote backup created
      def store_backup_record
        VCS::FileBackup.create!(
          file_version: file_version,
          remote_file_id: remote_backup.id
        )
      end
    end
  end
end
