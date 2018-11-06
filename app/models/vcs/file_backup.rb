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
    validates :external_id, presence: true, on: %i[create update]

    # TODO: after_destroy --> destroy backup if this is last reference to it

    # Create a backup for the provided file resource
    def self.backup(staged_file_to_backup)
      new(file_snapshot: staged_file_to_backup.current_snapshot)
        .tap(&:capture)
        .tap(&:save)
    end

    # Capture a backup of the file resource snapshot and store in archive
    def capture
      return false unless valid?(:capture)

      # Create backup
      # TODO: Refactor to file_resource.duplicate_remote
      file = staged_file_remote.duplicate(
        name: file_snapshot.name,
        parent_id: archive_folder_id
      )

      return false unless file.present?

      self.external_id = file.id
    end

    # TODO: Refactor onto snapshot
    def external_link
      Providers::GoogleDrive::Link
        .for(external_id: external_id, mime_type: file_snapshot.mime_type)
    end

    private

    def archive
      @archive ||= file_snapshot.file_record.repository.archive
    end

    def archive_folder_id
      archive.external_id
    end

    def staged_file_remote
      sync_adapter_class.new(file_snapshot.external_id)
    end

    def provider
      'GoogleDrive'
    end

    def sync_adapter_class
      "Providers::#{provider}::FileSync".constantize
    end
  end
end
