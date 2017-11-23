# frozen_string_literal: true

# Delay jobs with DelayedJob when tagged with :delayed_job tag.
# Copied from: https://www.sitepoint.com/delayed-jobs-best-practices/
RSpec.configure do |config|
  config.around(:each, :delayed_job) do |example|
    old_value = Delayed::Worker.delay_jobs
    Delayed::Worker.delay_jobs = true
    Delayed::Job.destroy_all

    example.run

    Delayed::Worker.delay_jobs = old_value
  end
end
