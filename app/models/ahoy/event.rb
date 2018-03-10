# frozen_string_literal: true

module Ahoy
  # Ahoy::Event represents a single page action during a user's visit
  class Event < ApplicationRecord
    include Ahoy::QueryMethods

    self.table_name = 'ahoy_events'

    belongs_to :visit
    belongs_to :user, class_name: 'Profiles::User', optional: true
  end
end
