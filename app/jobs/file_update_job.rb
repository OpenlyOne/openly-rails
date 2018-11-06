# frozen_string_literal: true

# Check Google Drive for any changes/updates to files
# Set job to run recurringly every 10 seconds.
class FileUpdateJob < ApplicationJob
  queue_as :file_update
  queue_with_priority 10

  def perform(*args)
    token = args[0][:token]

    # retrieve changes since token
    change_list =
      Providers::GoogleDrive::ApiConnection.default.list_changes(token)

    process_changes(change_list)

    create_new_file_update_job(change_list)
  end

  private

  # check for new changes in 10 seconds
  def check_for_changes_later(new_start_page_token)
    self.class
        .set(wait: 10.seconds)
        .perform_later(token: new_start_page_token)
  end

  # create a new job
  def create_new_file_update_job(change_list)
    if change_list.next_page_token.present?
      list_changes_on_next_page(change_list.next_page_token)
    else
      check_for_changes_later(change_list.new_start_page_token)
    end
  end

  # fetch the next page of changes immediately
  def list_changes_on_next_page(next_page_token)
    self.class.perform_later(token: next_page_token)
  end

  # Process the fetched changes
  def process_changes(change_list)
    # Iterate through each change
    change_list.changes.each do |change|
      # TODO: Trigger ChangeProcessJob here
      process_change(change)
    end
  end

  # TODO: Rename this to ChangesListJob. Extract into ChangeProcessJob.
  def process_change(change)
    external_ids =
      [change.file_id].concat(change&.file&.parents.to_a).compact.uniq

    # Find branches that have either the file or its parents staged
    branches = VCS::Branch.where_staged_files_include_external_id(external_ids)

    # Pull the file in each branch
    branches.find_each do |branch|
      # TODO: Extract into FileUpdateJob
      VCS::StagedFile.find_or_initialize_by(
        external_id: change.file_id,
        branch: branch
      ).pull
    end
  end
end
