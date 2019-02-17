# frozen_string_literal: true

# Wrapper class for activity notifications
class Notification < ActivityNotification::Notification
  include HasJobs

  acts_as_hashids secret: ENV['HASH_ID_SECRET']

  # Create a new instance of the notification helper for the notifying object
  # Must pass key: in the options
  def self.notification_helper_for(notifying_object, options = {})
    action = options.fetch(:key).split('.').last.titleize
    klass  = notifying_object.model_name.to_s.pluralize

    "Notifications::#{klass}::#{action}".constantize
                                        .new(notifying_object,
                                             options.except(:key))
  end

  # Delegate the path to the notification helper
  def notifiable_path
    notification_helper.path
  end

  # The partial name
  def partial_name
    path_to_partial = notification_helper.class.to_s
                                         .downcase.gsub('::', '/')
                                         .partition('/').last
    "#{path_to_partial}_notification"
  end

  # The title for the notification
  def title
    notification_helper.title
  end

  alias to_partial_path partial_name
  alias subject_line title
  alias unread? unopened?
  alias notifying_object notifiable

  private

  def notification_helper
    @notification_helper ||=
      self.class.notification_helper_for(notifiable, source: notifier, key: key)
  end
end
