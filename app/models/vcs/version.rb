# frozen_string_literal: true

module VCS
  # A unique version of a file's data (name, content, parent, ...)
  class Version < ApplicationRecord
    include VCS::Resourceable

    # Associations
    belongs_to :file, autosave: false
    belongs_to :parent, class_name: 'VCS::File', optional: true
    belongs_to :content

    has_one :backup, class_name: 'VCS::FileBackup', dependent: :destroy,
                     inverse_of: :file_version, foreign_key: :file_version_id
    has_one :repository, through: :file

    # Callbacks
    # Prevent updates to file version; versions are immutable.
    before_update do
      raise ActiveRecord::ReadOnlyRecord
    end

    # Attributes
    alias_attribute :versionable_id, :file_id

    # TODO: Add in support for different providers set on repository level
    # # Return versions with provider ID from file resource
    # scope :with_provider_id, lambda {
    #   joins(:file_resource)
    #     .select('file_resource_versions.*')
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
    validates :file_id,         presence: true
    validates :name,            presence: true
    validates :mime_type,       presence: true
    validates :file_id,
              uniqueness: {
                scope: %i[name content_id mime_type parent_id],
                message: 'already has a version with these attributes'
              },
              if: :new_record?

    # Finds an existing version with the given attributes or creates a new one
    def self.for(attributes)
      find_or_create_by_attributes(
        core_attributes(attributes),
        supplemental_attributes(attributes)
      )
    end

    # The set of core attributes that uniquely identify a version
    def self.core_attributes(attributes)
      attributes
        .symbolize_keys
        .slice(*core_attribute_keys)
    end

    # The set of core attributes that uniquely identify a version
    def self.core_attribute_keys
      %i[file_id name content_id mime_type parent_id]
    end

    # Find or create a version from the set of core attributes, optionally
    # updating its supplemental attributes
    def self.find_or_create_by_attributes(core, supplements)
      create_with(supplements).find_or_create_by!(core).tap do |version|
        version.update_supplemental_attributes(supplements)
      end
    end

    # The set of supplemental attributes to a version
    def self.supplemental_attributes(attributes)
      attributes.symbolize_keys.slice(*supplemental_attribute_keys)
    end

    # The set of supplemental attributes to a version
    def self.supplemental_attribute_keys
      %i[thumbnail_id]
    end

    # The plain text content of this version
    def plain_text_content
      content&.plain_text
    end

    # TODO: Support different providers at repository level
    # Return provider ID of repository, either preloaded or from file
    # def provider_id
    #   0
    # end

    # Return the hashed ID of the file ID
    def hashed_file_id
      VCS::File.id_to_hashid(file_id)
    end

    # Create a new version from the current version's attributes and set the
    # current version to the new one
    def version!
      self.id = self.class.for(attributes).id
      reload
    end

    # Update any new supplemental attributes, such as thumbnail
    def update_supplemental_attributes(new_attributes)
      # Return all supplemental attribute key-value pairs that are not
      # supplemental attributes of current version
      # h1: {thumbnail: '1', attribute_a: 'abc'}
      # h2: {thumbnail: '2'}
      # --> {thumbnail: '1', attribute_a: 'abc'}
      # See: https://stackoverflow.com/a/24642938/6451879
      attributes_to_update =
        (new_attributes.to_a - supplemental_attributes.to_a).to_h

      # If there are no attributes to update, exit
      return if attributes_to_update.none?

      # Update current version, bypassing callbacks
      update_columns(attributes_to_update)
    end

    private

    def supplemental_attributes
      self.class.supplemental_attributes(attributes)
    end
  end
end
