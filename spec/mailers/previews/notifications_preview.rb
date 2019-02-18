# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/notifications
class NotificationsPreview < ActionMailer::Preview
  def contribution_accept_notification
    show_notification(
      Contribution.notifications.where(key: 'contribution.accept').first
    )
  end

  def contribution_create_notification
    show_notification(
      Contribution.notifications.where(key: 'contribution.create').first
    )
  end

  def reply_create_notification
    show_notification(Reply.notifications.first)
  end

  def vcs_commit_notification
    show_notification(VCS::Commit.notifications.first)
  end

  private

  def show_notification(notification)
    NotificationsMailer.notification_email(notification)
  end
end
