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

    def folder_import_jobs
      Delayed::Job.where(queue: 'folder_import',
                         delayed_reference_id: id,
                         delayed_reference_type: model_name.param_key)
    end

    private

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
