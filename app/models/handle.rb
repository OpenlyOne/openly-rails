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
  # Do not allow identifier change
  attr_readonly :identifier

  # Validations
  # Profile id must be unique within each type
  validates :profile_id, uniqueness: { scope: :profile_type }
  # Profile type must be user
  validates :profile_type, inclusion: { in: %w[User] }
  # Identifier must be present
  validates :identifier, presence: true
  # Conduct validations only if identifier is present
  with_options if: :identifier? do
    validates :identifier, length: { in: 3..26 }
    validates :identifier,
              format: {
                with:     /\A[a-zA-Z0-9_]+\z/,
                message:  'must contain only letters, numbers, and underscores'
              }
    validates :identifier,
              format: {
                with:     /\A[a-zA-Z0-9]/,
                message:  'must begin with a letter or number'
              }
    validates :identifier,
              format: {
                with:     /[a-zA-Z0-9]\z/,
                message:  'must end with a letter or number'
              }
  end
  # Validate uniqueness unless identifier has errors
  validates :identifier,
            uniqueness: { case_sensitive: true },
            unless: proc { |handle| handle.errors[:identifier].any? }
end
