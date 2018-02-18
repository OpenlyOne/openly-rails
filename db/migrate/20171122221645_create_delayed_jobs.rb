# frozen_string_literal: true

# Create table for storing Delayed Job background jobs
class CreateDelayedJobs < ActiveRecord::Migration[5.1]
  def change
    create_table :delayed_jobs, force: true do |t|
      # Allows some jobs to jump to the front of the queue
      t.integer :priority, default: 0, null: false
      # Provides for retries, but still fail eventually.
      t.integer :attempts, default: 0, null: false
      # YAML-encoded string of the object that will do work
      t.text :handler,                 null: false
      # reason for last failure (See Note below)
      t.text :last_error
      # When to run. Could be Time.zone.now for immediately, or sometime in the
      # future.
      t.datetime :run_at
      # Set when a client is working on this object
      t.datetime :locked_at
      # Set when all retries have failed (actually, by default, the record is
      # deleted instead)
      t.datetime :failed_at
      # Who is working on this object (if locked)
      t.string :locked_by
      # The name of the queue this job is in
      t.string :queue
      t.timestamps null: true

      t.index %w[priority run_at], name: 'delayed_jobs_priority'

      # Store a reference to the model entity instance that this job is related
      # to. For example, an email notification might be related to a user.
      t.bigint :delayed_reference_id
      t.string :delayed_reference_type

      # Add index on the queue column to improve performance of querying
      # specific job queues
      t.index :queue
    end
  end
end
