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
    has_one :handle, as: :profile, dependent: :destroy, inverse_of: :profile
    has_many :projects, as: :owner, dependent: :destroy, inverse_of: :owner

    # Attributes
    accepts_nested_attributes_for :handle

    # Validations
    validates :handle, presence: true, on: :create
    validates :name, presence: true

    # Use handle identifier as param in URLs
    def to_param
      try(:handle).try(:identifier)
    end
  end
end
