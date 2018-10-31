# frozen_string_literal: true

# Import a Google Drive folder and create new FolderImportJobs for any
# subfolders
class FolderImportJob < ApplicationJob
  queue_as :folder_import
  queue_with_priority 100

  def perform(*args)
    variables_from_arguments(*args)

    file = VCS::StagedFile.find(staged_file_id)

    file.pull_children

    # Schedule a new import job for any subfolders
    file.subfolders.each do |subfolder|
      schedule_folder_import_job_for(subfolder)
    end
  end

  private

  attr_accessor :staged_file_id, :project, :setup

  # Create a new FolderImportJob for the given file resource
  def schedule_folder_import_job_for(staged_file)
    FolderImportJob.perform_later(
      reference:      setup,
      staged_file_id: staged_file.id
    )
  end

  # Set instance variables from the job's arguments
  def variables_from_arguments(*args)
    reference_id          = args[0][:reference_id]
    self.setup            = Project::Setup.find(reference_id)
    self.staged_file_id   = args[0][:staged_file_id]
  end
end
