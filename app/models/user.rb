# frozen_string_literal: true

# Every account has a user. The user model handles the aspects that are visible
# to other users, such as the user's name (as opposed to an account's email and
# password, for example)
class User < ApplicationRecord
  # Associations
  belongs_to :account
  has_one :handle, as: :profile, dependent: :destroy, inverse_of: :profile

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
