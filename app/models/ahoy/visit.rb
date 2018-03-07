# frozen_string_literal: true

module Ahoy
  # Ahoy::Visit represents a single user's visit to our website
  # One visit consists of many events.
  class Visit < ApplicationRecord
    self.table_name = 'ahoy_visits'

    has_many :events, class_name: 'Ahoy::Event'
    belongs_to :user, optional: true
  end
end
