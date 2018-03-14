# frozen_string_literal: true

# Handles projects that belong to a profile (owner)
# rubocop:disable Metrics/ClassLength
class Project < ApplicationRecord
  # Associations
  belongs_to :owner, class_name: 'Profiles::Base'
  has_and_belongs_to_many :collaborators, class_name: 'Profiles::User',
                                          association_foreign_key: 'profile_id',
                                          validate: false

  has_one :staged_root_folder,
          -> { where is_root: true },
          class_name: 'StagedFile',
          dependent: :delete
  has_one :root_folder, class_name: 'FileResource',
                        through: :staged_root_folder,
                        source: :file_resource

  has_many :staged_files, dependent: :destroy
  has_many :file_resources_in_stage, class_name: 'FileResource',
                                     through: :staged_files,
                                     source: :file_resource

  has_many :staged_non_root_files,
           -> { where is_root: false },
           class_name: 'StagedFile'
  has_many :non_root_file_resources_in_stage, class_name: 'FileResource',
                                              through: :staged_non_root_files,
                                              source: :file_resource do
    # Return non root file resources in stage that have a current snapshot
    def with_current_snapshot
      where.not(file_resources: { current_snapshot: nil })
    end
  end

  has_many :non_root_file_snapshots_in_stage,
           class_name: 'FileResource::Snapshot',
           through: :non_root_file_resources_in_stage,
           source: :current_snapshot

  has_many :all_revisions, class_name: 'Revision', dependent: :destroy
  has_many :revisions, -> { where is_published: true } do
    def create_draft_and_commit_files!(author)
      ::Revision.create_draft_and_commit_files_for_project!(
        proxy_association.owner,
        author
      )
    end
  end

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

  # Scopes
  # Projects where profile is owner or collaborator
  scope :where_profile_is_owner_or_collaborator, lambda { |profile|
    Project
      .left_joins(:collaborators)
      .where('owner_id = :profile_id ' \
             'OR profiles_projects.profile_id = :profile_id',
             profile_id: profile.id)
      .distinct
  }

  # Validations
  # Title & slug must be present
  validates :title, presence: true, length: { maximum: 50 }
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
    validates :slug,
              format: {
                without:  /\Aedit\z/,
                message:  'is not available'
              }
  end
  # Validate uniqueness unless slug has errors
  validates :slug,
            uniqueness: {
              case_sensitive: true,
              scope: :owner_id
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
  def link_to_google_drive_folder=(link)
    @link_to_google_drive_folder = link
    @google_drive_folder_id = folder_link_to_id(link)
  end

  def public?
    is_public
  end

  # List of tags, separated by comma
  def tag_list
    tags.join(', ')
  end

  # Set tags by list of tags (must be comma-separated)
  def tag_list=(tag_list)
    self.tags =
      tag_list.split(',')     # Split tag list by comma delimiter
              .map(&:squish)  # Strips spaces and squishes consecutive spaces
              .select(&:present?) # Ignore empty tags
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

  # Parse a link to a Google Drive folder into its ID
  def folder_link_to_id(link_to_file)
    matches = link_to_file.match(%r{\/folders\/?(.+)})
    matches ? matches[1] : nil
  end

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
    @google_drive_folder_id ||= root_folder&.external_id
  end

  # Import a Google Drive Folder
  def import_google_drive_folder
    # Create the root folder
    self.root_folder =
      FileResources::GoogleDrive
      .find_or_initialize_by(external_id: google_drive_folder_id)
      .tap(&:pull)

    # Start recursive FolderImportJob
    FolderImportJob.perform_later(reference: self,
                                  file_resource_id: root_folder.id)
  rescue StandardError
    # An error was found -- make sure root is not persisted
    staged_root_folder&.destroy
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
    file = Providers::GoogleDrive::ApiConnection
           .default.find_file!(google_drive_folder_id)

    validate_folder_mime_type(file)
  rescue Google::Apis::ClientError => _e
    errors.add(
      :link_to_google_drive_folder,
      'appears to be inaccessible. Have you shared the resource with '\
      "#{Settings.google_drive_tracking_account}?"
    )
  end

  # Validation: Is the file a folder?
  def validate_folder_mime_type(folder)
    return if Providers::GoogleDrive::MimeType.folder?(folder.mime_type)
    errors.add(
      :link_to_google_drive_folder,
      'appears not to be a Google Drive folder'
    )
  end
end
# rubocop:enable Metrics/ClassLength
