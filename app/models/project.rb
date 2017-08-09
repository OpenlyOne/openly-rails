# frozen_string_literal: true

# Handles projects that belong to a profile (owner)
class Project < ApplicationRecord
  belongs_to :owner, polymorphic: true

  # Attributes
  # Do not allow owner change
  attr_readonly :owner_id, :owner_type

  # Validations
  # Owner type must be user
  validates :owner_type, inclusion: { in: %w[User] }
  validates :title, presence: true, length: { maximum: 50 }
  # Slug must be present
  validates :slug, presence: true
  # Conduct validations only if slug is present
  with_options if: :slug? do
    validates :slug, length: { maximum: 50 }
    validates :slug,
              format: {
                with:     /\A[a-zA-Z0-9-]+\z/,
                message:  'must contain only letters, numbers, and dashes'
              }
    validates :slug,
              format: {
                with:     /\A[a-zA-Z0-9]/,
                message:  'must begin with a letter or number'
              }
    validates :slug,
              format: {
                with:     /[a-zA-Z0-9]\z/,
                message:  'must end with a letter or number'
              }
  end
  # Validate uniqueness unless slug has errors
  validates :slug,
            uniqueness: {
              case_sensitive: true,
              scope: %i[owner_type owner_id]
            },
            unless: proc { |project| project.errors[:slug].any? }

  # Trim whitespaces around title
  def title=(title)
    super(title.try(:strip))
  end
end
