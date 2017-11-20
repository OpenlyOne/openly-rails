# frozen_string_literal: true

# Handles projects that belong to a profile (owner)
class Project < ApplicationRecord
  # Associations
  belongs_to :owner, polymorphic: true
  has_one :root_folder,
          -> { where parent_id: nil },
          class_name: 'FileItems::Folder',
          dependent: :destroy
  has_many :suggestions, class_name: 'Discussions::Suggestion',
                         dependent: :destroy
  has_many :issues, class_name: 'Discussions::Issue', dependent: :destroy
  has_many :questions, class_name: 'Discussions::Question', dependent: :destroy

  # Attributes
  # Do not allow owner change
  attr_readonly :owner_id, :owner_type

  # Callbacks
  # Auto-generate slug from title
  before_validation :generate_slug_from_title, if: :title?, unless: :slug?

  # Validations
  # Owner type must be user
  validates :owner_type, inclusion: { in: %w[Profiles::Base] }
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
      Profiles::Base.find_by!(handle: id_or_profile_handle)
                    .projects.find_by_slug!(project_slug)
    end
  end

  # Import a Google Drive Folder
  def import_google_drive_folder(id_of_folder)
    # Raise error if files have already been imported
    raise "Project #{id}: Root folder already exists" if root_folder&.persisted?

    # Create the root folder
    root_folder = GoogleDrive.get_file(id_of_folder)
    root_folder =
      create_root_folder(name: 'root', google_drive_id: root_folder.id)

    # Recursively add files
    recursively_import_google_drive_folder(root_folder)
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

  # Retrieve a list of Google Drive files inside the FileItems::Folder instance
  def recursively_import_google_drive_folder(folder)
    GoogleDrive.list_files_in_folder(folder.google_drive_id).each do |file|
      new_file = folder.children.create(
        google_drive_id: file.id,   name: file.name,
        mime_type: file.mime_type,  project: self
      )
      if new_file.mime_type.include? 'google-apps.folder'
        recursively_import_google_drive_folder(new_file)
      end
    end
  end
end
