# frozen_string_literal: true

# Handles projects that belong to a profile (owner)
# rubocop:disable Metrics/ClassLength
class Project < ApplicationRecord
  include VersionControl

  # Associations
  belongs_to :owner, polymorphic: true

  # Attributes
  # Do not allow owner change
  attr_readonly :owner_id, :owner_type

  # Accessors
  attr_reader :link_to_google_drive_folder
  attr_accessor :import_google_drive_folder_on_save

  # Callbacks
  # Auto-generate slug from title
  before_validation :generate_slug_from_title, if: :title?, unless: :slug?
  # Import Google Drive folder
  after_save :import_google_drive_folder,
             if: :import_google_drive_folder_on_save
  # Reset value of import_google_drive_folder_on_save
  after_save { self.import_google_drive_folder_on_save = false }

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
  validate :link_to_google_drive_folder_is_valid,
           :link_to_google_drive_is_accessible_folder,
           if: proc { |project| project.import_google_drive_folder_on_save }

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

  # The base path for version controlled repositories of Project instances
  def self.repository_folder_path
    Rails.root.join(
      Settings.file_storage,
      'projects'
    ).cleanpath.to_s
  end

  # The absolute link to the Google Drive root folder
  def link_to_google_drive_folder=(link)
    @link_to_google_drive_folder = link
    @google_drive_folder_id = GoogleDrive.link_to_id(link)
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

  # The ID of the Google Drive folder associated with this project
  def google_drive_folder_id
    @google_drive_folder_id ||= files&.root&.google_drive_id
  end

  # Import a Google Drive Folder
  def import_google_drive_folder
    # Create the root folder
    drive_file = GoogleDrive.get_file(google_drive_folder_id)
    files.create_root(drive_file.to_h)

    # Start recursive FolderImportJob
    FolderImportJob.perform_later(reference: self, folder_id: files.root.id)
  rescue StandardError
    # An error was found -- make sure root is not persisted
    files.root&.destroy
    # Re-raise original error
    raise
  end

  # Validation: Is the link to the Google Drive folder valid?
  def link_to_google_drive_folder_is_valid
    return unless google_drive_folder_id.nil?

    errors.add(:link_to_google_drive_folder,
               'appears not to be a valid Google Drive link')
  end

  # Validation: Is the link to the Google Drive folder accessible and a folder?
  def link_to_google_drive_is_accessible_folder
    return if google_drive_folder_id.nil?
    file = GoogleDrive.get_file(google_drive_folder_id)

    validate_folder_mime_type(file)
  rescue Google::Apis::ClientError => _e
    errors.add(
      :link_to_google_drive_folder,
      'appears to be inaccessible. Have you shared the resource with '\
      "#{Settings.google_drive_tracking_account}?"
    )
  end

  # The file path for the project instance's version controlled repository
  def repository_file_path
    return nil unless id_in_database.present?

    Pathname.new(self.class.repository_folder_path)
            .join(id_in_database.to_s)
            .cleanpath.to_s
  end

  # Validation: Is the file a folder?
  def validate_folder_mime_type(folder)
    return if folder.mime_type == FileItems::Folder.new.mime_type
    errors.add(
      :link_to_google_drive_folder,
      'appears not to be a Google Drive folder'
    )
  end
end
