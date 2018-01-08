# frozen_string_literal: true

# Import a Google Drive folder and create new FolderImportJobs for any
# subfolders
class FolderImportJob < ApplicationJob
  queue_as :folder_import
  queue_with_priority 100

  def perform(*args)
    variables_from_arguments(*args)

    # TODO: Lock repository after receiving files
    GoogleDrive.list_files_in_folder(@folder_id).each do |file|
      # create a new file
      file = create_or_update_file(file, @folder_id, @project)

      # schedule a new job if the file is a folder
      schedule_folder_import_job_for(file.id) if file.directory?
    end
  end

  private

  # Create a new file from the given Google Drive file, parent ID, & project
  def create_or_update_file(google_drive_file, parent_folder_id, project)
    project.files.create_or_update(
      id:             google_drive_file.id,
      name:           google_drive_file.name,
      mime_type:      google_drive_file.mime_type,
      parent_id:      parent_folder_id,
      version:        google_drive_file.version,
      modified_time:  google_drive_file.modified_time
    )
  end

  # Create a new FolderImportJob for the folder
  def schedule_folder_import_job_for(folder_id)
    FolderImportJob.perform_later(
      reference_id:   @reference_id,
      reference_type: @reference_type,
      folder_id:      folder_id
    )
  end

  # Sets instance variables from the job's arguments
  def variables_from_arguments(*args)
    @reference_type = args[0][:reference_type]
    @reference_id   = args[0][:reference_id]
    @project        = Project.find(@reference_id)
    @folder_id      = args[0][:folder_id]
  end
end
