# Preview all emails at http://localhost:3000/rails/mailers/notifications
class NotificationsPreview < ActionMailer::Preview
  def notification_email
    notification = Notification.first
    NotificationsMailer.notification_email(notification)
  end
end
