# frozen_string_literal: true

class Project
  # Track setup process of a project (primarily file import)
  class Setup < ApplicationRecord
    # Associations
    belongs_to :project

    # Aliases
    alias begin update

    # Attributes
    attr_accessor :link

    # Delegations
    delegate :root_folder, :root_folder=, to: :project

    # Callbacks
    after_create :set_root_and_import_files, if: :id_from_link
    after_destroy :destroy_all_jobs

    # Validations
    validates :project_id, uniqueness: { message: 'has already been set up' }

    with_options on: :create do
      validates :link, presence: true
      validate :link_is_valid, unless: :any_errors?
      validate :file_is_accessible, unless: :any_errors?
      validate :file_is_folder, unless: :any_errors?
    end

    # Check if the setup process has finished and mark setup as completed, if so
    def check_if_complete
      complete if persisted? && folder_import_jobs.none?
    end

    # Return true if the setup has been completed
    def completed?
      is_completed
    end

    # Return all folder import jobs that belong to this setup process
    def folder_import_jobs
      jobs.where(queue: FolderImportJob.queue_name)
    end

    # Return true if setup has been started, but not completed
    def in_progress?
      persisted? && !completed?
    end

    # Return true if the setup has not yet been started
    def not_started?
      new_record?
    end

    # Schedule a job to check for the completion of the setup process
    def schedule_setup_completion_check_job
      SetupCompletionCheckJob
        .set(wait: 3.seconds)
        .perform_later(reference: self)
    end

    # Return all setup completion check jobs that belong to this setup process
    def setup_completion_check_jobs
      jobs.where(queue: SetupCompletionCheckJob.queue_name)
    end

    private

    # Return true if one ore more validation errors have occurred
    def any_errors?
      errors.any?
    end

    # Mark setup as completed
    def complete
      create_origin_revision_in_project
      update(is_completed: true)
    end

    def create_origin_revision_in_project
      author    = project.owner
      revision  = project.revisions.create_draft_and_commit_files!(author)
      revision.update(is_published: true,
                      title: 'Import Files',
                      summary: 'Import Files from Google Drive.')
    end

    # Destroy all jobs related to this setup process
    def destroy_all_jobs
      jobs.destroy_all
    end

    # Validation: File behind link is accessible by tracking account
    def file_is_accessible
      return unless file.deleted?
      errors.add(:link, 'appears to be inaccessible. Have you shared the ' \
                        'resource with ' \
                        "#{Settings.google_drive_tracking_account}?")
    end

    # Validation: File behind link is a folder
    def file_is_folder
      return if file.folder?
      errors.add(:link, 'appears not to be a Google Drive folder')
    end

    # Get the ID from the link
    def id_from_link
      matches = link.match(%r{\/folders\/?(.+)})
      matches ? matches[1] : nil
    end

    # Set file by finding an existing file resource or creating a new one from
    # the ID from link
    def file
      @file ||=
        FileResources::GoogleDrive
        .find_or_initialize_by(external_id: id_from_link) # Find or initialize
        .tap { |file| file.pull if file.new_record? }     # Pull if new record
    end

    # Return the delayed jobs that belong to this setup process
    def jobs
      Delayed::Job.where(delayed_reference_id: id,
                         delayed_reference_type: model_name.param_key)
    end

    # Validation: Link points to a Google Drive folder
    def link_is_valid
      return if id_from_link.present?
      errors.add(:link, 'appears not to be a valid Google Drive link')
    end

    # Set a Google Drive Folder as root, begin folder import process, and
    # schedule a check for the completion of this setup process
    def set_root_and_import_files
      set_root_folder
      start_folder_import_job_for_root_folder
      schedule_setup_completion_check_job
    end

    # Set the root folder to file
    def set_root_folder
      self.root_folder = file
    end

    # Start a (recursive) FolderImportJob for the root_folder
    def start_folder_import_job_for_root_folder
      FolderImportJob
        .perform_later(reference: self, file_resource_id: root_folder.id)
    end
  end
end
