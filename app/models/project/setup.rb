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
    after_create :set_root_and_import_files

    # Validations
    validates :project_id, uniqueness: { message: 'has already been set up' }

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
      Delayed::Job.where(queue: 'folder_import',
                         delayed_reference_id: id,
                         delayed_reference_type: model_name.param_key)
    end

    # Return true if setup has been started, but not completed
    def in_progress?
      persisted? && !completed?
    end

    # Return true if the setup has not yet been started
    def not_started?
      new_record?
    end

    private

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

    # Get the ID from the link
    def id_from_link
      matches = link.match(%r{\/folders\/?(.+)})
      matches ? matches[1] : nil
    end

    # Set a Google Drive Folder as root and begin folder import process
    def set_root_and_import_files
      set_root_folder
      start_folder_import_job_for_root_folder
    end

    # Set the root folder by finding an existing file resource or creating a
    # new one
    def set_root_folder
      self.root_folder = FileResources::GoogleDrive
                         .find_or_initialize_by(external_id: id_from_link)

      # Pull root folder if it is a new record
      root_folder.pull if root_folder.new_record?
    end

    # Start a (recursive) FolderImportJob for the root_folder
    def start_folder_import_job_for_root_folder
      FolderImportJob
        .perform_later(reference: self, file_resource_id: root_folder.id)
    end
  end
end
