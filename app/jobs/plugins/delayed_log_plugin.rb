# frozen_string_literal: true

require 'delayed_job'

# Log all SQL queries happening during DelayedJob in the delayed job log
# Credit: https://stackoverflow.com/a/26599729/6451879
class DelayedJobLogSetup < Delayed::Plugin
  callbacks do |lifecycle|
    lifecycle.before(:execute) do |worker|
      Rails.logger = worker.logger
      ActiveRecord::Base.logger = worker.logger
    end
  end
end
