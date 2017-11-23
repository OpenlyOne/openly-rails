# frozen_string_literal: true

require 'delayed_job'

# Adds support for storing a reference object's id and and type to the database
class ModelReferencePlugin < Delayed::Plugin
  callbacks do |lifecycle|
    lifecycle.before(:enqueue) do |job, *_args, &_block|
      # break if no arguments have been passed
      next unless job.payload_object.job_data['arguments'].is_a? Array

      job_args        = job.payload_object.job_data['arguments'][0]
      reference_id    = job_args['reference_id']
      reference_type  = job_args['reference_type']

      # break if reference id or type is nil
      next unless reference_id && reference_type

      # assign id and type to job
      job.delayed_reference_id = reference_id
      job.delayed_reference_type = reference_type
    end
  end
end
