# frozen_string_literal: true

# Import a Google Drive folder and create new FolderImportJobs for any
# subfolders
class FolderImportJob < ApplicationJob
  queue_as :folder_import
  queue_with_priority 100

  def perform(*args)
    variables_from_arguments(*args)

    GoogleDrive.list_files_in_folder(@folder.google_drive_id).each do |file|
      # create a new file
      new_file = create_file(file, @folder_id, @reference_id)

      # schedule a new job if the file is a folder
      if new_file.mime_type.include? 'google-apps.folder'
        schedule_folder_import_job_for(new_file)
      end
    end
  end

  private

  # Create a new file from the given Google Drive file, parent ID, & project ID
  def create_file(google_drive_file, parent_folder_id, project_id)
    FileItems::Base.create(
      google_drive_id:  google_drive_file.id,
      name:             google_drive_file.name,
      mime_type:        google_drive_file.mime_type,
      parent_id:        parent_folder_id,
      project_id:       project_id,
      version:          google_drive_file.version,
      modified_time:    google_drive_file.modified_time
    ).tap(&:commit!)
  end

  # Create a new FolderImportJob for the folder
  def schedule_folder_import_job_for(folder)
    FolderImportJob.perform_later(
      reference_id:   @reference_id,
      reference_type: @reference_type,
      folder_id:      folder.id
    )
  end

  # Sets instance variables from the job's arguments
  def variables_from_arguments(*args)
    @reference_type = args[0][:reference_type]
    @reference_id   = args[0][:reference_id]
    @folder_id      = args[0][:folder_id]
    @folder         = FileItems::Folder.find(@folder_id)
  end
end
