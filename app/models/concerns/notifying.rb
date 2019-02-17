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

    attr_accessor :skip_notifications

    before_destroy :destroy_notifications

    def self.notifications
      Notification.where(notifiable_type: model_name.to_s)
    end
  end

  def notifications
    Notification.where(notifiable: self)
  end

  def skip_notifications?
    skip_notifications == true
  end

  private

  attr_accessor :notification_helper

  def destroy_notifications
    notifications.destroy_all
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

  def trigger_notifications(key)
    return if skip_notifications?

    self.notification_helper =
      Notification.notification_helper_for(self, key: key)
    notify :accounts, key: key
  end
end
