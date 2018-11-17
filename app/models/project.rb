# frozen_string_literal: true

# Handles projects that belong to a profile (owner)
# rubocop:disable Metrics/ClassLength
class Project < ApplicationRecord
  # Associations
  belongs_to :owner, class_name: 'Profiles::Base'
  has_and_belongs_to_many :collaborators,
                          class_name: 'Profiles::User',
                          association_foreign_key: 'profile_id',
                          validate: false,
                          before_add: :grant_read_access_to_archive,
                          before_remove: :remove_read_access_to_archive

  has_one :setup, class_name: 'Project::Setup', dependent: :destroy

  belongs_to :master_branch, class_name: 'VCS::Branch',
                             optional: true,
                             dependent: :destroy

  belongs_to :repository, class_name: 'VCS::Repository',
                          dependent: :destroy,
                          optional: true

  has_many :revisions, class_name: 'VCS::Commit',
                       through: :master_branch, source: :commits

  has_one :archive, class_name: 'VCS::Archive', through: :repository

  # Attributes
  # Do not allow owner change
  attr_readonly :owner_id
  # Set to true to skip archive setup
  attr_accessor :skip_archive_setup

  # Delegations
  delegate :build_archive, to: :repository
  delegate :archive, to: :repository, prefix: true
  delegate :in_progress?, :completed?, to: :setup, prefix: true, allow_nil: true
  delegate :staged_files, to: :master_branch

  # Callbacks
  # Auto-generate slug from title
  before_validation :generate_slug_from_title, if: :title?, unless: :slug?
  # Set up repository and master branch
  before_create :create_repository,                     unless: :repository
  before_create :create_master_branch_with_repository,  unless: :master_branch
  # Set up archive for storing file backups
  # TODO: Refactor into background job
  after_create :setup_archive, unless: :skip_archive_setup

  # Scopes
  # Projects where profile is owner or collaborator
  scope :where_profile_is_owner_or_collaborator, lambda { |profile|
    left_joins(:collaborators)
      .where('owner_id = :profile_id ' \
             'OR profiles_projects.profile_id = :profile_id',
             profile_id: profile.id)
      .distinct
  }
  # Projects where setup has been completed
  scope :where_setup_is_complete, lambda {
    joins(:setup).where(project_setups: { is_completed: true })
  }
  # Find project by profile handle and slug
  scope :find_by_handle_and_slug!, lambda { |handle, slug|
    joins(:owner).find_by!(profiles: { handle: handle }, slug: slug)
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

  def public?
    is_public
  end

  # Return true if the setup process for this project has not started
  def setup_not_started?
    setup.nil? ? true : setup.not_started?
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

  # Build master branch for the repository
  def create_master_branch_with_repository
    create_master_branch(repository: repository)
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

  # Grant view access to archive to the new collaborator
  def grant_read_access_to_archive(collaborator)
    archive&.grant_read_access_to(collaborator.account.email)
  end

  # Remove view access to archive from the removed collaborator
  def remove_read_access_to_archive(collaborator)
    archive&.remove_read_access_from(collaborator.account.email)
  end

  # Set up the archive folder for this project
  def setup_archive
    return unless repository.present?

    repository_archive.present? ||
      build_archive(name: title, owner_account_email: owner.account.email)

    return if repository_archive.setup_completed?

    repository_archive.tap(&:setup).tap(&:save)
  end
end
# rubocop:enable Metrics/ClassLength
