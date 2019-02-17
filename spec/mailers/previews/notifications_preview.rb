# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/notifications
class NotificationsPreview < ActionMailer::Preview
  def contribution_notification
    show_notification(Contribution.notifications.first)
  end

  def vcs_commit_notification
    show_notification(VCS::Commit.notifications.first)
  end

  private

  def show_notification(notification)
    NotificationsMailer.notification_email(notification)
  end
end
