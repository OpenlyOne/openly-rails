# frozen_string_literal: true

# Check if a project's setup process has been completed
class SetupCompletionCheckJob < ApplicationJob
  queue_as :setup_completion_check
  queue_with_priority 100

  def perform(*args)
    variables_from_arguments(*args)

    setup.check_if_complete

    setup.schedule_setup_completion_check_job unless setup.completed?
  end

  private

  attr_accessor :setup

  # Set instance variables from the job's arguments
  def variables_from_arguments(*args)
    reference_id  = args[0][:reference_id]
    self.setup    = Project::Setup.find(reference_id)
  end
end
