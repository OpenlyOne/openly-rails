# frozen_string_literal: true

module VCS
  # A unique snapshot of a file's data (name, content, parent, ...)
  # rubocop:disable Metrics/ClassLength
  class FileSnapshot < ApplicationRecord
    include VCS::Resourceable

    # Associations
    belongs_to :file_record, autosave: false
    belongs_to :file_record_parent, class_name: 'VCS::FileRecord',
                                    optional: true
    belongs_to :content

    has_one :backup, class_name: 'VCS::FileBackup', dependent: :destroy,
                     inverse_of: :file_snapshot
    has_one :repository, through: :file_record

    # Callbacks
    # Prevent updates to file snapshot; snapshots are immutable.
    before_update do
      raise ActiveRecord::ReadOnlyRecord
    end

    # Attributes
    alias_attribute :snapshotable_id, :file_record_id
    # TODO: Legacy support, REMOVE soon
    alias_attribute :parent_id, :file_record_parent_id

    # Scopes
    scope :joins_current_snapshot, lambda {
      left_joins(file_record: :current_snapshot)
    }

    # Snapshots where the file has been deleted (current snapshot is nil)
    scope :where_current_snapshot_is_nil, lambda {
      joins_current_snapshot
        .where('current_snapshots_file_resources IS ?', nil)
    }

    # Snapshots where the file currently has the given parent
    scope :where_current_snapshot_parent, lambda { |parent|
      joins_current_snapshot
        .where(
          'current_snapshots_file_resources.file_record_parent_id = ?', parent
        )
    }

    # Snapshots that are committed in the given revision
    scope :of_revision, lambda { |revision|
      joins(:committing_files).where(committed_files: { revision_id: revision })
    }

    # TODO: Add in support for different providers set on repository level
    # # Return snapshots with provider ID from file resource
    # scope :with_provider_id, lambda {
    #   joins(:file_resource)
    #     .select('file_resource_snapshots.*')
    #     .select('file_resources.provider_id')
    # }

    # Order committed files by
    # 1) directory first and
    # 2) file name in ascending alphabetical order, case insensitive
    scope :order_by_name_with_folders_first, lambda {
      merge(
        FileInBranch.order_by_name_with_folders_first(
          table: table_name
        )
      )
    }

    # Validations
    validates :file_record_id,    presence: true
    validates :name,              presence: true
    validates :content_version,   presence: true
    validates :mime_type,         presence: true
    validates :remote_file_id,    presence: true
    validates :file_record_id,
              uniqueness: {
                scope: %i[name content_id mime_type file_record_parent_id],
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

    # TODO: Content generation should not be happening here. Move to
    # =>    FileInBranch instead
    def self.repository(attributes)
      VCS::FileRecord.find(attributes[:file_record_id])&.repository
    end

    # TODO: Content generation should not be happening here. Move to
    # =>    FileInBranch instead
    def self.content_id(attributes)
      attributes.symbolize_keys!
      VCS::Operations::ContentGenerator.generate(
        repository: repository(attributes),
        remote_file_id: attributes[:remote_file_id],
        remote_content_version_id: attributes[:content_version]
      )&.id
    end

    # TODO: Content generation should not be happening here. Move to
    # =>    FileInBranch instead
    # The set of core attributes that uniquely identify a snapshot
    def self.core_attributes(attributes)
      attributes
        .symbolize_keys
        .reverse_merge(content_id: content_id(attributes))
        .slice(*core_attribute_keys)
    end

    # The set of core attributes that uniquely identify a snapshot
    def self.core_attribute_keys
      %i[file_record_id name content_id mime_type file_record_parent_id]
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
      %i[thumbnail_id remote_file_id content_version]
    end

    # The plain text content of this snapshot
    def plain_text_content
      content&.plain_text
    end

    # Return provider ID of file resource, either preloaded or from file
    # resource
    def provider_id
      0
    end

    # Create a new snapshot from the current snapshot's attributes and set the
    # current snapshot to the new one
    def snapshot!
      self.id = self.class.for(attributes).id
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
  # rubocop:enable Metrics/ClassLength
end
