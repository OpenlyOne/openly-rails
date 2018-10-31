# frozen_string_literal: true

# Restore a file snapshot
class FileRestoreJob < ApplicationJob
  queue_as :file_restore
  queue_with_priority 50

  def perform(*args)
    variables_from_arguments(*args)

    VCS::Operations::FileRestore
      .new(
        snapshot: snapshot,
        file_record_id: file_record_id,
        target_branch: branch
      ).restore
  end

  private

  attr_accessor :file_record_id, :branch, :snapshot

  # Set instance variables from the job's arguments
  def variables_from_arguments(*args)
    reference_id        = args[0][:reference_id]
    self.branch         = VCS::Branch.find(reference_id)
    self.snapshot       = VCS::FileSnapshot.find_by(id: args[0][:snapshot_id])
    self.file_record_id = args[0][:file_record_id]
  end
end
