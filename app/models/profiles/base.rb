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
    has_many :projects, as: :owner, dependent: :destroy, inverse_of: :owner

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

    # Use handle identifier as param in URLs
    def to_param
      handle
    end
  end
end
