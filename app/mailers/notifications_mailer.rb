# frozen_string_literal: true

# Send notification emails
class NotificationsMailer < ApplicationMailer
  default from: 'Upshift One <notification@upshift.one>'

  # Overwrite .send_notification_email to push reference to DeliveryJob
  def self.send_notification_email(notification, options = {})
    notification_email(notification, options.merge(reference: notification))
  end

  # Send a notification email
  def notification_email(notification, _options = {})
    @notification = notification
    mail(to: account_to_recipient(notification.target),
         subject: notification.subject_line,
         template_name: 'notification_email')
  end

  private

  def account_to_recipient(account)
    "#{account.user.name} <#{account.email}>"
  end
end
