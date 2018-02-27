# frozen_string_literal: true

class FileResource
  # A unique snapshot of a FileResource's data (name, content, parent, ...)
  class Snapshot < ApplicationRecord
    # Associations
    belongs_to :file_resource, autosave: false, optional: false
    belongs_to :parent, class_name: 'FileResource', optional: true

    # Callbacks
    # Prevent updates to file snapshot; snapshots are immutable.
    before_update do
      raise ActiveRecord::ReadOnlyRecord
    end

    # Attributes
    alias_attribute :snapshotable_id, :file_resource_id

    # Validations
    validates :file_resource_id,  presence: true
    validates :name,              presence: true
    validates :content_version,   presence: true
    validates :mime_type,         presence: true
    validates :external_id,       presence: true
    validates :file_resource_id,
              uniqueness: {
                scope: %i[external_id content_version mime_type name parent_id],
                message: 'already has a snapshot with these attributes'
              },
              if: :new_record?
  end
end
