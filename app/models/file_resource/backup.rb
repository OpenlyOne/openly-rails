# frozen_string_literal: true

class FileResource
  # A permanent backup of a file resource snapshot
  class Backup < ApplicationRecord
    # Associations
    belongs_to :file_resource_snapshot, class_name: 'FileResource::Snapshot',
                                        dependent: false
    belongs_to :archive, class_name: 'Project::Archive', dependent: false
    belongs_to :file_resource, dependent: false

    # Validations
    validates :file_resource_snapshot_id,
              uniqueness: { message: 'already has a backup' }

    # TODO: after_destroy --> destroy backup if this is last reference to it
  end
end
