# frozen_string_literal: true

# Use Delayed Job for processing ActiveJobs
Rails.application.config.active_job.queue_adapter = :delayed_job

# Register plugin for storing model references in the database
require "#{Rails.root}/app/jobs/plugins/model_reference_plugin.rb"
Delayed::Worker.plugins << ModelReferencePlugin

# Log SQL queries to the delayed log
require "#{Rails.root}/app/jobs/plugins/delayed_log_plugin.rb"
Delayed::Worker.plugins << DelayedJobLogSetup

# Do not destroy failed jobs (so we can figure out what went wrong and re-run
# them)
Delayed::Worker.destroy_failed_jobs = false

# Abort job if not complete after 15 minutes
Delayed::Worker.max_run_time = 15.minutes

# Delay jobs - unless we are in the test environment
Delayed::Worker.delay_jobs = true
Delayed::Worker.delay_jobs = false if Rails.env.test?

# Set up logging for delayed job
logfile = Rails.root.join('log', "delayed_job_#{Rails.env}.log")
Delayed::Worker.logger = Logger.new(logfile)
