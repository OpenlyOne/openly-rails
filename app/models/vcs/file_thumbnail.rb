# frozen_string_literal: true

module VCS
  # Thumbnails for files
  class FileThumbnail < ApplicationRecord
    # Associations
    belongs_to :file_record

    has_many :file_snapshots, foreign_key: :thumbnail_id, dependent: :nullify
    has_many :files_in_branches, class_name: 'FileInBranch',
                                 foreign_key: :thumbnail_id,
                                 dependent: :nullify

    # Attachments
    has_attached_file :image,
                      styles: { original: '200x200#' },
                      path: ':attachment_path/:class/' \
                            ':file_record_id/:remote_file_id/:version_id/' \
                            ':hash.:content_type_extension',
                      url:  ':attachment_url/:class/' \
                            ':file_record_id/:remote_file_id/:version_id/' \
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
      scope: %i[file_record_id remote_file_id],
      message: 'with remote ID already exists for this file record'
    }, if: :new_record?

    # Callbacks
    # Prevent updates to file thumbnail; thumbnails are immutable.
    before_update do
      raise ActiveRecord::ReadOnlyRecord
    end

    # Parse the file resource to a hash of attributes
    def self.attributes_from_file_in_branch(file_in_branch)
      {
        file_record_id: file_in_branch.file_record_id,
        remote_file_id: file_in_branch.remote_file_id,
        version_id:  file_in_branch.thumbnail_version_id
      }
    end

    # Find or initialize a Thumbnail instance by provider ID, remote ID, and
    # version ID
    def self.find_or_initialize_by_file_in_branch(file_in_branch)
      find_or_initialize_by(
        attributes_from_file_in_branch(file_in_branch)
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

    # Set remote ID and version ID from the given file in branch
    def file_in_branch=(file_in_branch)
      assign_attributes(
        self.class.attributes_from_file_in_branch(file_in_branch)
      )
    end

    # Set the image from proc object that returns a raw image
    def raw_image=(raw_image)
      self.image = StringIO.new(raw_image.call)
    end
  end
end
