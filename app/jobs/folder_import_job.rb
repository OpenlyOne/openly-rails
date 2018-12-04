# frozen_string_literal: true

# Import a Google Drive folder and create new FolderImportJobs for any
# subfolders
class FolderImportJob < ApplicationJob
  queue_as :folder_import
  queue_with_priority 100

  def perform(*args)
    variables_from_arguments(*args)

    file = VCS::FileInBranch.find(file_in_branch_id)

    file.pull_children

    # Schedule a new import job for any subfolders
    file.subfolders.each do |subfolder|
      schedule_folder_import_job_for(subfolder)
    end
  end

  private

  attr_accessor :file_in_branch_id, :project, :setup

  # Create a new FolderImportJob for the given file resource
  def schedule_folder_import_job_for(file_in_branch)
    FolderImportJob.perform_later(
      reference:         setup,
      file_in_branch_id: file_in_branch.id
    )
  end

  # Set instance variables from the job's arguments
  def variables_from_arguments(*args)
    reference_id            = args[0][:reference_id]
    self.setup              = Project::Setup.find(reference_id)
    self.file_in_branch_id  = args[0][:file_in_branch_id]
  end
end
