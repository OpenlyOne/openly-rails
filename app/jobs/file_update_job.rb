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

    update_files
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

  # update files based on retrieved change list
  def update_files
    @change_list.changes.each do |change|
      FileItems::Base.update_all_projects_from_change(change)
    end
  end
end
