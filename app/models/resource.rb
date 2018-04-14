# frozen_string_literal: true

# A single file resource
class Resource < ApplicationRecord
  belongs_to :owner, class_name: 'Profiles::Base'

  # Validations
  validates_presence_of :title
  validates_presence_of :mime_type
  validates_presence_of :link
end
