# frozen_string_literal: true

# Wrapper class for activity notifications
class Notification < ActivityNotification::Notification
  acts_as_hashids secret: ENV['HASH_ID_SECRET']
end
