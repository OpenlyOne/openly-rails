# frozen_string_literal: true

module Ahoy
  class Store < Ahoy::DatabaseStore
  end
end

# set to true for JavaScript tracking
Ahoy.api = false

# set low priority for geocoding jobs
Ahoy.job_queue = :low_priority

# disable geocoding in tests
Ahoy.geocode = false if Rails.env.test?
