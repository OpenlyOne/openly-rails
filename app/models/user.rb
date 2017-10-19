# frozen_string_literal: true

# Every account has a user. The user model handles the aspects that are visible
# to other users, such as the user's name (as opposed to an account's email and
# password, for example)
class User < ApplicationRecord
  # Change the route key, so that the url_for helper automatically generates
  # the right route
  # See: https://stackoverflow.com/a/13131811/6451879
  # TODO: Use STI for User (table: Profiles)
  # TODO: See: https://gist.github.com/sj26/5843855
  model_name.class_eval do
    def route_key
      singular_route_key.pluralize
    end

    def singular_route_key
      'profile'
    end
  end

  # Associations
  belongs_to :account
  has_one :handle, as: :profile, dependent: :destroy, inverse_of: :profile
  has_many :projects, as: :owner, dependent: :destroy, inverse_of: :owner
  has_many :discussions, class_name: 'Discussions::Base',
                         dependent: :destroy,
                         foreign_key: :initiator_id,
                         inverse_of: :initiator
  has_many :replies, dependent: :destroy,
                     foreign_key: :author_id,
                     inverse_of: :author

  # Attributes
  accepts_nested_attributes_for :handle
  # Do not allow account change
  attr_readonly :account_id

  # Validations
  validates :handle, presence: true, on: :create
  validates :name, presence: true

  # Use username when generating routes
  def to_param
    username
  end

  # Get handle of user (username)
  def username
    try(:handle).try(:identifier)
  end
end
