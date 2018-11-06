# frozen_string_literal: true

module VCS
  # Thumbnails for files
  class FileThumbnail < ApplicationRecord
    # Attachments
    has_attached_file :image,
                      styles: { original: '200x200#' },
                      path: ':attachment_path/:class/' \
                            ':external_id/:version_id/' \
                            ':hash.:content_type_extension',
                      url:  ':attachment_url/:class/' \
                            ':external_id/:version_id/' \
                            ':hash.:content_type_extension',
                      default_url: '/fallback/file_resources/thumbnail.png',
                      hash_secret: ENV['THUMBNAIL_HASH_SECRET']

    # Validations
    validates_with AttachmentPresenceValidator,
                   attributes: :image
    validates_with AttachmentSizeValidator,
                   attributes: :image,
                   less_than: 1.megabytes
    validates_with AttachmentContentTypeValidator,
                   attributes: :image,
                   content_type: %w[image/jpeg image/gif image/png],
                   message: 'must be JPEG, PNG, or GIF'
    validates :version_id, uniqueness: {
      scope: %i[external_id],
      message: 'with external ID already exists'
    }, if: :new_record?

    # Callbacks
    # Prevent updates to file thumbnail; thumbnails are immutable.
    before_update do
      raise ActiveRecord::ReadOnlyRecord
    end

    # Parse the file resource to a hash of attributes
    def self.attributes_from_staged_file(staged_file)
      {
        external_id: staged_file.external_id,
        version_id:  staged_file.thumbnail_version_id
      }
    end

    # Find or initialize a Thumbnail instance by provider ID, external ID, and
    # version ID
    def self.find_or_initialize_by_staged_file(staged_file)
      find_or_initialize_by(
        attributes_from_staged_file(staged_file)
      )
    end

    # Preload thumbnail for the given objects
    def self.preload_for(objects)
      # Fetch all thumbnails that belong to objects
      records = where(id: objects.map(&:thumbnail_id).compact.uniq)

      # Associate thumbnails with the owning objects
      objects.each do |owner|
        record = records.find { |r| r.id == owner.thumbnail_id }

        association = owner.association(:thumbnail)
        association.target = record
        association.set_inverse_instance(record)
      end
    end

    # Set external ID and version ID from the given staged file
    def staged_file=(staged_file)
      assign_attributes(
        self.class.attributes_from_staged_file(staged_file)
      )
    end

    # Set the image from proc object that returns a raw image
    def raw_image=(raw_image)
      self.image = StringIO.new(raw_image.call)
    end
  end
end
