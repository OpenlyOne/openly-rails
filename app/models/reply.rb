# frozen_string_literal: true

# A single reply in a discussion about a contribution
class Reply < ApplicationRecord
  include Notifying

  # Associations
  belongs_to :author, class_name: 'Profiles::User'
  belongs_to :contribution

  # Callbacks
  after_create :trigger_create_notifications

  # Validations
  validates :content, presence: true

  private

  def trigger_create_notifications
    trigger_notifications('reply.create')
  end
end
