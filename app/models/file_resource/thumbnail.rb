# frozen_string_literal: true

class FileResource
  # Thumbnails for file resources
  class Thumbnail < ApplicationRecord
    # Attachments
    has_attached_file :image,
                      styles: { original: '200x200#' },
                      path: ':attachment_path/:class/' \
                            ':provider_id/:external_id/:version_id/' \
                            ':hash.:content_type_extension',
                      url:  ':attachment_url/:class/' \
                            ':provider_id/:external_id/:version_id/' \
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
      scope: %i[external_id provider_id],
      message: 'with external ID and provider already exist'
    }, if: :new_record?

    # Callbacks
    # Prevent updates to file thumbnail; thumbnails are immutable.
    before_update do
      raise ActiveRecord::ReadOnlyRecord
    end

    # Parse the file resource to a hash of attributes
    def self.attributes_from_file_resource(file_resource)
      {
        provider_id: file_resource.provider_id,
        external_id: file_resource.external_id,
        version_id:  file_resource.thumbnail_version_id
      }
    end

    # Find or initialize a Thumbnail instance by provider ID, external ID, and
    # version ID
    def self.find_or_initialize_by_file_resource(file_resource)
      find_or_initialize_by(
        attributes_from_file_resource(file_resource)
      )
    end

    # Set provider ID, external ID, and version ID from the given file resource
    def file_resource=(file_resource)
      assign_attributes(
        self.class.attributes_from_file_resource(file_resource)
      )
    end

    # Set the image from proc object that returns a raw image
    def raw_image=(raw_image)
      self.image = StringIO.new(raw_image.call)
    end
  end
end
