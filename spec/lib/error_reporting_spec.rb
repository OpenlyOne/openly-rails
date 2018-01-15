# frozen_string_literal: true

# class TestJob < ApplicationJob
#
# end

RSpec.describe 'error reporting' do
  # turn on error reporting
  around(:all) do |example|
    initial_rollbar_setting = Rollbar.configuration.enabled
    Rollbar.configuration.enabled = true
    example.run
    Rollbar.configuration.enabled = initial_rollbar_setting
  end

  describe 'when an error occurs in the application' do
    it 'creates an ErrorReportJob' do
      expect(ErrorReportJob).to receive(:perform_later)
      Rollbar.error 'trigger an error'
    end
  end

  describe 'when an error occurs in a background job' do
    # turn on delaying jobs for spec
    around(:all) do |example|
      initial_delayed_job_setting = Delayed::Worker.delay_jobs
      Delayed::Worker.delay_jobs = true
      example.run
      Delayed::Worker.delay_jobs = initial_delayed_job_setting
    end

    it 'creates an ErrorReportJob' do
      class JobDouble < ApplicationJob
        def perform(*_)
          raise 'error during job'
        end
      end

      JobDouble.perform_later({})

      expect(Rollbar).to receive(:process_from_async_handler)

      Delayed::Worker.new.work_off
    end
  end
end
