# frozen_string_literal: true

module VCS
  # A permanent backup of a file resource snapshot
  class FileBackup < ApplicationRecord
    # Associations
    belongs_to :file_snapshot, inverse_of: :backup

    # Validations
    validates :file_snapshot_id,
              presence: { message: 'must exist' },
              uniqueness: { message: 'already has a backup' }
    validates :archive, presence: true, on: :capture
    validates :remote_file_id, presence: true, on: %i[create update]

    # TODO: after_destroy --> destroy backup if this is last reference to it

    # Create a backup for the provided file in branch
    def self.backup(file_in_branch_to_backup)
      new(file_snapshot: file_in_branch_to_backup.current_snapshot)
        .tap(&:capture)
        .tap(&:save)
    end

    # Capture a backup of the file resource snapshot and store in archive
    def capture
      return false unless valid?(:capture)

      # Create backup
      # TODO: Refactor to file_resource.duplicate_remote
      file = file_in_branch_remote.duplicate(
        name: file_snapshot.name,
        parent_id: archive_folder_id
      )

      return false unless file.present?

      self.remote_file_id = file.id
    end

    # TODO: Refactor onto snapshot
    def link_to_remote
      Providers::GoogleDrive::Link
        .for(remote_file_id: remote_file_id, mime_type: file_snapshot.mime_type)
    end

    private

    def archive
      @archive ||= file_snapshot.file.repository.archive
    end

    def archive_folder_id
      archive.remote_file_id
    end

    def file_in_branch_remote
      sync_adapter_class.new(file_snapshot.remote_file_id)
    end

    def provider
      'GoogleDrive'
    end

    def sync_adapter_class
      "Providers::#{provider}::FileSync".constantize
    end
  end
end
