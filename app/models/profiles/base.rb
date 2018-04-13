# frozen_string_literal: true

module Profiles
  # STI parent class for users and teams
  class Base < ApplicationRecord
    self.table_name = 'profiles'

    # Change the route key, so that the url_for helper automatically generates
    # the right route
    # See: https://stackoverflow.com/a/13131811/6451879
    model_name.class_eval do
      def route_key
        singular_route_key.pluralize
      end

      def singular_route_key
        'profile'
      end
    end

    # Associations
    has_many :projects, foreign_key: :owner_id,
                        dependent: :destroy,
                        inverse_of: :owner
    has_and_belongs_to_many :collaborations, class_name: 'Project',
                                             foreign_key: 'profile_id',
                                             validate: false

    # Profile Picture
    has_attached_file :picture,
                      styles: {
                        large: ['250x250#', :jpg],
                        medium: ['100x100#', :jpg]
                      },
                      default_style: :medium,
                      path: ':attachment_path/profiles/:id_partition/picture/' \
                            ':style.:extension',
                      url:  ':attachment_url/profiles/:id_partition/picture/' \
                            ':style.:extension',
                      default_url: '/fallback/profiles/picture.jpg'
    has_attached_file :banner,
                      styles: {
                        original: ['1600x500#', :jpg]
                      },
                      default_style: :original,
                      path: ':attachment_path/profiles/:id_partition/banner/' \
                            ':style.:extension',
                      url:  ':attachment_url/profiles/:id_partition/banner/' \
                            ':style.:extension',
                      default_url: '/fallback/profiles/banner.jpg'

    # Attributes
    # Do not allow handle to change
    attr_readonly :handle

    # Validations
    validates :name, presence: true
    validates :handle, presence: true
    # Conduct validations only if handle is present
    with_options if: :handle? do
      validates :handle, length: { in: 3..26 }
      validates :handle,
                format: {
                  with:     /\A[a-zA-Z0-9_]+\z/,
                  message:  'must contain only letters, numbers, and ' \
                            'underscores'
                }
      validates :handle,
                format: {
                  with:     /\A[a-zA-Z0-9]/,
                  message:  'must begin with a letter or number'
                }
      validates :handle,
                format: {
                  with:     /[a-zA-Z0-9]\z/,
                  message:  'must end with a letter or number'
                }
    end
    # Validate uniqueness unless handle has errors
    validates :handle,
              uniqueness: { case_sensitive: true },
              unless: proc { |handle| handle.errors[:identifier].any? }

    # Profile picture
    validates_with AttachmentSizeValidator,
                   attributes: :picture,
                   less_than: 10.megabytes
    validates_with AttachmentContentTypeValidator,
                   attributes: :picture,
                   content_type: %w[image/jpeg image/gif image/png],
                   message: 'must be JPEG, PNG, or GIF'

    # Use handle identifier as param in URLs
    def to_param
      handle
    end
  end
end
