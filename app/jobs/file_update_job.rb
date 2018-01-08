# frozen_string_literal: true

# Check Google Drive for any changes/updates to files
# Set job to run recurringly every 10 seconds.
class FileUpdateJob < ApplicationJob
  queue_as :file_update
  queue_with_priority 10

  def perform(*args)
    token = args[0][:token]

    # retrieve changes since token
    @change_list = GoogleDrive.list_changes(token)

    process_changes(@change_list)

    create_new_file_update_job
  end

  private

  # check for new changes in 10 seconds
  def check_for_changes_later
    FileUpdateJob
      .set(wait: 10.seconds)
      .perform_later(token: @change_list.new_start_page_token)
  end

  # create a new job
  def create_new_file_update_job
    if @change_list.next_page_token.present?
      list_changes_on_next_page
    else
      check_for_changes_later
    end
  end

  # fetch the next page of changes immediately
  def list_changes_on_next_page
    FileUpdateJob.perform_later(token: @change_list.next_page_token)
  end

  # Process the fetched changes
  def process_changes(change_list)
    # Iterate through each change
    change_list.changes.each do |change|
      # Search for file/parent in each project and update/create if applicable
      update_file_in_any_project(
        # Transform change item to attribute hash
        GoogleDrive.attributes_from_change_record(change)
      )
    end
  end

  # Search all project repositories for file or parent and create/update
  def update_file_in_any_project(new_attributes)
    Project.find_each_repository(:lock) do |repository|
      file_id = new_attributes[:id]
      parent_id = new_attributes[:parent_id]

      # Check whether file or parent exists
      if repository.stage.files.exists?([file_id, parent_id]).any? { |_, v| v }

        # File or parent exists, create_or_update file
        repository.stage.files.create_or_update(new_attributes)
      end
    end
  end
end
