# frozen_string_literal: true

# Add support for creating notifications of the notifying object
module Notifying
  extend ActiveSupport::Concern

  included do
    acts_as_notifiable :accounts,
                       targets: :notification_recipients,
                       notifier: :notification_source,
                       dependent_notifications: :do_nothing,
                       notifiable_path: :path_to_notifying_object

    before_destroy :destroy_notifications
  end

  private

  def destroy_notifications
    Notification.where(notifiable: self).destroy_all
  end

  def notification_recipients
    notification_helper.recipients
  end

  def notification_source
    notification_helper.source
  end

  def path_to_notifying_object
    notification_helper.path
  end

  def notification_helper
    @notification_helper ||= Notification.notification_helper_for(self)
  end

  def trigger_notifications
    notify :accounts
  end
end
