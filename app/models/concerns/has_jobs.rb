# frozen_string_literal: true

# Destroy all associated jobs on destruction of owning object
module HasJobs
  extend ActiveSupport::Concern

  included do
    after_destroy :destroy_jobs
  end

  # Return the delayed jobs that belong to this setup process
  def jobs
    Delayed::Job.where(delayed_reference_id: id,
                       delayed_reference_type: model_name.param_key)
  end

  private

  def destroy_jobs
    jobs.destroy_all
  end
end
