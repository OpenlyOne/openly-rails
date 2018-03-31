# frozen_string_literal: true

class FileResource
  # A unique snapshot of a FileResource's data (name, content, parent, ...)
  class Snapshot < ApplicationRecord
    include Resourceable

    # Associations
    belongs_to :file_resource, autosave: false, optional: false
    belongs_to :parent, class_name: 'FileResource', optional: true

    has_many :committing_files, class_name: 'CommittedFile',
                                foreign_key: :file_resource_snapshot_id

    # Callbacks
    # Prevent updates to file snapshot; snapshots are immutable.
    before_update do
      raise ActiveRecord::ReadOnlyRecord
    end

    # Attributes
    alias_attribute :snapshotable_id, :file_resource_id
    attr_writer :provider

    # Scopes
    scope :joins_current_snapshot, lambda {
      left_joins(file_resource: :current_snapshot)
    }

    # Snapshots where the file has been deleted (current snapshot is nil)
    scope :where_current_snapshot_is_nil, lambda {
      joins_current_snapshot
        .where('current_snapshots_file_resources IS ?', nil)
    }

    # Snapshots where the file currently has the given parent
    scope :where_current_snapshot_parent, lambda { |parent|
      joins_current_snapshot
        .where('current_snapshots_file_resources.parent_id = ?', parent)
    }

    # Snapshots that are committed in the given revision
    scope :of_revision, lambda { |revision|
      joins(:committing_files).where(committed_files: { revision_id: revision })
    }

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

    def provider
      @provider ||= file_resource.provider
    end
  end
end
