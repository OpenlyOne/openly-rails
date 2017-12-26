# frozen_string_literal: true

# Handles projects that belong to a profile (owner)
# rubocop:disable Metrics/ClassLength
class Project < ApplicationRecord
  include VersionControl

  # Associations
  belongs_to :owner, polymorphic: true
  has_one :root_folder,
          -> { where parent_id: nil },
          class_name: 'FileItems::Folder',
          dependent: :destroy
  has_many :files, class_name: 'FileItems::Base'

  # Attributes
  # Do not allow owner change
  attr_readonly :owner_id, :owner_type

  # Accessors
  attr_accessor :import_google_drive_folder_on_save

  # Callbacks
  # Auto-generate slug from title
  before_validation :generate_slug_from_title, if: :title?, unless: :slug?
  # Import Google Drive folder
  around_save :import_google_drive_folder,
              if: proc { |project| project.import_google_drive_folder_on_save },
              unless: proc { |project| project.errors.any? }
  # Reset value of import_google_drive_folder_on_save
  after_save { self.import_google_drive_folder_on_save = false }

  # Scopes
  # Returns projects that have Google drive files
  scope :having_google_drive_files, (lambda do |array_of_ids|
    results = Project.none
    array_of_ids.select(&:present?).each do |id|
      results = results.or(
        Project.joins(:files).where(file_items: { google_drive_id: id })
      )
    end
    results.distinct
  end)

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

  # The absolute link to the Google Drive root folder
  def link_to_google_drive_folder
    @link_to_google_drive_folder ||=
      if google_drive_folder_id
        "https://drive.google.com/drive/folders/#{google_drive_folder_id}"
      end
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
    @google_drive_folder_id ||= root_folder&.google_drive_id
  end

  # Import a Google Drive Folder
  def import_google_drive_folder
    # Create the root folder
    drive_file = GoogleDrive.get_file(google_drive_folder_id)
    files.create_root(drive_file.to_h)

    # save (raise Rollback if not successful)
    unless yield
      # delete root
      FileUtils.remove_dir(files.root.send(:path))
      return false
    end

    # Start recursive FolderImportJob
    FolderImportJob.perform_later(reference: self, folder_id: files.root.id)
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

  # Get the file path for the project's git repository
  def repository_file_path
    return nil unless id_in_database.present?

    Rails.root.join(
      Settings.file_storage,
      'projects',
      id_in_database.to_s
    ).cleanpath.to_s
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
