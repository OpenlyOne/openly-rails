# frozen_string_literal: true

module VCS
  # A permanent backup of a file resource version
  class FileBackup < ApplicationRecord
    # Associations
    belongs_to :file_version, class_name: 'VCS::Version', inverse_of: :backup

    # Validations
    validates :file_version_id,
              presence: { message: 'must exist' },
              uniqueness: { message: 'already has a backup' }
    validates :remote_file_id, presence: true

    # TODO: after_destroy --> destroy backup if this is last reference to it

    # TODO: Refactor onto version
    def link_to_remote
      Providers::GoogleDrive::Link
        .for(remote_file_id: remote_file_id, mime_type: file_version.mime_type)
    end
  end
end
