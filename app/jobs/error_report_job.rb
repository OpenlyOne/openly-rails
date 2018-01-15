# frozen_string_literal: true

# Report the error to Rollbar
class ErrorReportJob < ApplicationJob
  queue_as :error_report
  queue_with_priority 1

  def self.call(payload)
    ErrorReportJob.perform_later(payload)
  end

  def perform(payload)
    Rollbar.process_from_async_handler(payload)
  end
end
