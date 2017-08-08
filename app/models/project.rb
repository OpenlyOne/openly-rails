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

  # Trim whitespaces around title
  def title=(title)
    super(title.try(:strip))
  end
end
