# frozen_string_literal: true

class Project
  # Track setup process of a project (primarily file import)
  class Setup < ApplicationRecord
    include HasJobs

    # Associations
    belongs_to :project

    # Aliases
    alias begin update

    # Attributes
    attr_accessor :link

    # Delegations
    delegate :master_branch, to: :project

    # Callbacks
    after_create :set_root_and_import_files, if: :id_from_link

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
      author  = project.owner
      commit  = master_branch.commits.create_draft_and_commit_files!(author)
      commit.update(is_published: true,
                    title: 'Import Files',
                    summary: 'Import Files from Google Drive.')
    end

    # Validation: File behind link is accessible by tracking account
    def file_is_accessible
      # TODO: Add check for file.inaccessible?
      # => Then we can remove the 'unless root?' from
      # the line 'mark_as_removed unless root?' in VCS::StagedFile
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
    # HACK: Just checking for a word with more than 25 characters is not a good
    #       approach to solving this problem and can result in false positives
    # TODO: Outsource link-to-ID parsing to Providers::GoogleDrive::Link
    def id_from_link
      matches = link.match(/[-\w]{25,}/)
      matches ? matches[0] : nil
    end

    # Set file by fetching a new one from the ID from link
    def file
      @file ||=
        master_branch
        .staged_files
        .build(is_root: true, remote_file_id: id_from_link)
        .tap(&:fetch)
    end

    # Validation: Link points to a Google Drive folder
    def link_is_valid
      return if id_from_link.present?

      errors.add(:link, 'appears not to be a valid Google Drive link')
    end

    # Set a Google Drive Folder as root, begin folder import process, and
    # schedule a check for the completion of this setup process
    def set_root_and_import_files
      file.tap(&:build_associations).tap(&:save)
      start_folder_import_job_for_root_folder
      schedule_setup_completion_check_job
    end

    # Start a (recursive) FolderImportJob for the root_folder
    def start_folder_import_job_for_root_folder
      FolderImportJob.perform_later(
        reference: self,
        staged_file_id: master_branch.root.id
      )
    end
  end
end
