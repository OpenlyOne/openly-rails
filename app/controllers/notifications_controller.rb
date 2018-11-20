# frozen_string_literal: true

# Controller for notifications
class NotificationsController < ApplicationController
  before_action :authenticate_account!

  # GET /notifications
  def index
    # HACK: Preload the repository relationship. Only works because we have
    # =>    only one type of notification and that notification supports the
    # =>    repository relationship.
    @notifications =
      notifications.includes(:notifier, notifiable: %i[repository])
  end

  # GET /notifications/:id
  def show
    @notification = notifications.find(params[:id])
    @notification.open!
    redirect_to @notification.notifiable_path
  end

  private

  def notifications
    Notification.where(target: current_account).order(id: :desc)
  end
end
