# frozen_string_literal: true

class FileResource
  # A unique snapshot of a FileResource's data (name, content, parent, ...)
  class Snapshot < ApplicationRecord
    include Resourceable

    # Associations
    belongs_to :file_resource, autosave: false, optional: false
    belongs_to :parent, class_name: 'FileResource', optional: true
    has_one :backup, class_name: 'FileResource::Backup',
                     dependent: :destroy,
                     foreign_key: :file_resource_snapshot_id

    has_many :committing_files, class_name: 'CommittedFile',
                                foreign_key: :file_resource_snapshot_id

    # Callbacks
    # Prevent updates to file snapshot; snapshots are immutable.
    before_update do
      raise ActiveRecord::ReadOnlyRecord
    end

    # Attributes
    alias_attribute :snapshotable_id, :file_resource_id

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

    # Return snapshots with provider ID from file resource
    scope :with_provider_id, lambda {
      joins(:file_resource)
        .select('file_resource_snapshots.*')
        .select('file_resources.provider_id')
    }

    # Order committed files by
    # 1) directory first and
    # 2) file name in ascending alphabetical order, case insensitive
    scope :order_by_name_with_folders_first, lambda {
      merge(
        FileResource.order_by_name_with_folders_first(
          table: 'file_resource_snapshots'
        )
      )
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

    # Finds an existing snapshot with the given attributes or creates a new one
    def self.for(attributes)
      find_or_create_by_attributes(
        core_attributes(attributes),
        supplemental_attributes(attributes)
      )
    end

    # The set of core attributes that uniquely identify a snapshot
    def self.core_attributes(attributes)
      attributes.symbolize_keys.slice(*core_attribute_keys)
    end

    # The set of core attributes that uniquely identify a snapshot
    def self.core_attribute_keys
      %i[file_resource_id name external_id content_version mime_type parent_id]
    end

    # Find or create a snapshot from the set of core attributes, optionally
    # updating its supplemental attributes
    def self.find_or_create_by_attributes(core, supplements)
      create_with(supplements).find_or_create_by!(core).tap do |snapshot|
        snapshot.update_supplemental_attributes(supplements)
      end
    end

    # The set of supplemental attributes to a snapshot
    def self.supplemental_attributes(attributes)
      attributes.symbolize_keys.slice(*supplemental_attribute_keys)
    end

    # The set of supplemental attributes to a snapshot
    def self.supplemental_attribute_keys
      %i[thumbnail_id]
    end

    # Return provider ID of file resource, either preloaded or from file
    # resource
    def provider_id
      read_attribute('provider_id') || file_resource.provider_id
    end

    # Create a new snapshot from the current snapshot's attributes and set the
    # current snapshot to the new one
    def snapshot!
      self.id = FileResource::Snapshot.for(attributes).id
      reload
    end

    # Update any new supplemental attributes, such as thumbnail
    def update_supplemental_attributes(new_attributes)
      # Return all supplemental attribute key-value pairs that are not
      # supplemental attributes of current snapshot
      # h1: {thumbnail: '1', attribute_a: 'abc'}
      # h2: {thumbnail: '2'}
      # --> {thumbnail: '1', attribute_a: 'abc'}
      # See: https://stackoverflow.com/a/24642938/6451879
      attributes_to_update =
        (new_attributes.to_a - supplemental_attributes.to_a).to_h

      # If there are no attributes to update, exit
      return if attributes_to_update.none?

      # Update current snapshot, bypassing callbacks
      update_columns(attributes_to_update)
    end

    private

    def supplemental_attributes
      self.class.supplemental_attributes(attributes)
    end
  end
end
