# frozen_string_literal: true

class FileResource
  # A permanent backup of a file resource snapshot
  class Backup < ApplicationRecord
    # Associations
    belongs_to :file_resource_snapshot, class_name: 'FileResource::Snapshot',
                                        dependent: false
    belongs_to :archive, class_name: 'Project::Archive', dependent: false
    belongs_to :file_resource, dependent: false, optional: true

    # Validations
    validates :file_resource_snapshot_id,
              uniqueness: { message: 'already has a backup' }
    validates :file_resource, presence: { message: 'must exist' },
                              on: %i[create update]

    # TODO: after_destroy --> destroy backup if this is last reference to it

    # Create a backup for the provided file resource
    def self.backup(file_resource_to_backup)
      new(
        file_resource_snapshot: file_resource_to_backup.current_snapshot,
        archive: file_resource_to_backup.staging_projects.first&.archive
      ).tap(&:capture).tap(&:save)
    end

    # Capture a backup of the file resource snapshot and store in archive
    def capture
      return false unless valid?(:capture)

      # Create backup
      # TODO: Refactor to file_resource.duplicate_remote
      file = file_resource_remote.duplicate(
        name: file_resource_snapshot.name,
        parent_id: archive_folder_id
      )

      return false unless file.present?
      create_file_resource!(file.id)
    end

    private

    def archive_folder_id
      archive.file_resource.external_id
    end

    # Create the file resource (backup)
    # TODO: Add support for is_tracked: false and avoid saving generic data
    # TODO: Store actual mime type for link generation
    def create_file_resource!(external_id)
      self.file_resource = file_resource_class.create!(
        external_id: external_id,
        name: 'Backup',
        mime_type: file_resource_snapshot.mime_type,
        content_version: 0
      )
    end

    def file_resource_remote
      sync_adapter_class.new(file_resource_snapshot.external_id)
    end

    def file_resource_class
      "FileResources::#{provider}".constantize
    end

    def provider
      'GoogleDrive'
    end

    def sync_adapter_class
      "Providers::#{provider}::FileSync".constantize
    end
  end
end
