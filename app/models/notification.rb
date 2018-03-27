# frozen_string_literal: true

# Wrapper class for activity notifications
class Notification < ActivityNotification::Notification
  include HasJobs

  acts_as_hashids secret: ENV['HASH_ID_SECRET']

  # Create a new instance of the notification helper for the notifying object
  def self.notification_helper_for(notifying_object, options = {})
    "Notifications::#{notifying_object.model_name}"
      .constantize
      .new(notifying_object, options)
  end

  # The partial name
  def partial_name
    "#{notifying_object.model_name.param_key}_notification"
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
      self.class.notification_helper_for(notifiable, source: notifier)
  end
end
