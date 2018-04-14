# frozen_string_literal: true

# A single file resource
class Resource < ApplicationRecord
  acts_as_hashids secret: ENV['HASH_ID_SECRET']

  # Associations
  belongs_to :owner, class_name: 'Profiles::Base'

  # Validations
  validates_presence_of :title
  validates_presence_of :mime_type
  validates_presence_of :link

  # Return the icon associated with the mime type of this resource
  def icon
    Providers::GoogleDrive::Icon.for(mime_type: mime_type)
  end
end
