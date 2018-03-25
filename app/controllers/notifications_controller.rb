# frozen_string_literal: true

# Controller for notifications
class NotificationsController < ApplicationController
  before_action :authenticate_account!

  # GET /notifications
  def index
    @notifications = notifications.includes(:notifier, notifiable: [:project])
  end

  # GET /notifications/:id
  def show
    @notification = notifications.find(params[:id])
    @notification.open!
    redirect_to @notification.notifiable_path
  end

  private

  def notifications
    current_account.notifications
  end
end
