# frozen_string_literal: true

# Restore a file version
class FileRestoreJob < ApplicationJob
  queue_as :file_restore
  queue_with_priority 50

  def perform(*args)
    variables_from_arguments(*args)

    VCS::Operations::FileRestore
      .new(
        version: version,
        file_id: file_id,
        target_branch: branch
      ).restore
  end

  private

  attr_accessor :file_id, :branch, :version

  # Set instance variables from the job's arguments
  def variables_from_arguments(*args)
    reference_id  = args[0][:reference_id]
    self.branch   = VCS::Branch.find(reference_id)
    self.version  = VCS::Version.find_by(id: args[0][:version_id])
    self.file_id  = args[0][:file_id]
  end
end
