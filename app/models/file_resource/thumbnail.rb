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
  end
end
