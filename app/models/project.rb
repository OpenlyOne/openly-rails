# frozen_string_literal: true

# Handles projects that belong to a profile (owner)
class Project < ApplicationRecord
  include VersionControl

  # Associations
  belongs_to :owner, polymorphic: true
  has_many :suggestions, class_name: 'Discussions::Suggestion',
                         dependent: :destroy

  # Attributes
  # Do not allow owner change
  attr_readonly :owner_id, :owner_type

  # Callbacks
  # Auto-generate slug from title
  before_validation :generate_slug_from_title, if: :title?, unless: :slug?

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

  # Find a project by profile handle and project slug
  # Also allows finding by ID, so that #reload still works
  def self.find(id_or_profile_handle, project_slug = nil)
    if project_slug.nil?
      # find by ID
      find_by_id! id_or_profile_handle
    else
      # find by handle and slug
      Profile.find(id_or_profile_handle).projects.find_by_slug! project_slug
    end
  end

  # Trim whitespaces around title
  def title=(title)
    super(title.try(:strip))
  end

  # Use slug when generating routes
  def to_param
    slug_in_database
  end

  private

  # Generate the project slug from the title by replacing whitespace with
  # dashes and removing all non-alphanumeric characters
  def generate_slug_from_title
    self.slug =
      title
      .gsub(/[^0-9a-z\s]/i, '') # replace all non-alphanumeric characters
      .strip                    # trim whitespaces
      .tr(' ', '-')             # replace whitespaces with dashes
      .downcase                 # all lowercase
  end

  # Get the file path for the project's git repository
  def repository_file_path
    Rails.root.join(
      Settings.file_storage,
      'projects',
      owner.to_param,
      "#{to_param}.git"
    ).to_s
  end
end
