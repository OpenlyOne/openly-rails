# frozen_string_literal: true

# Add support for creating notifications of the notifying object
module Notifying
  extend ActiveSupport::Concern

  included do
    acts_as_notifiable :accounts,
                       targets: :notification_recipients,
                       notifier: :notification_source,
                       dependent_notifications: :update_group_and_delete_all
  end

  private

  def notification_recipients
    Notification::Recipients.send(notification_method_name, self)
  end

  def notification_source
    Notification::Source.send(notification_method_name, self)
  end

  def notification_method_name
    "for_#{model_name.singular}"
  end

  def trigger_notifications
    notify :accounts
  end
end
