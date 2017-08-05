# frozen_string_literal: true

# Every user has a handle (username) by which they can be identified. We use a
# separately model because later on - when we implement the teams feature -
# teams will use the same implementation.
class Handle < ApplicationRecord
  # Associations
  belongs_to :profile, polymorphic: true

  # Attributes
  # Do not allow profile change
  attr_readonly :profile_id, :profile_type

  # Validations
  # Profile id must be unique within each type
  validates :profile_id, uniqueness: { scope: :profile_type }
  # Profile type must be user
  validates :profile_type, inclusion: { in: %w[User] }
  validates :identifier, presence: true, uniqueness: { case_sensitive: true }
end
