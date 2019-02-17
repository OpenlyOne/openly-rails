# frozen_string_literal: true

# Notification helper methods
module NotificationsHelper
  # Return all FactoryBot factories with notification as their parent
  def notification_factory_objects
    FactoryBot.factories.select do |factory|
      factory.instance_variable_get(:@parent) == :notification
    end
  end

  # Return an array of factory names for notification factories
  def notification_factories
    notification_factory_objects.map(&:name)
  end

  # Return a random notification factory
  def random_notification_factory
    notification_factories.sample
  end
end
