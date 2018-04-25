# frozen_string_literal: true

module Admin
  # Administration controller for managing accounts
  class AccountsController < Admin::ApplicationController
    before_action :ignore_blank_password, only: :update

    private

    # If password & password confirmation are both blank, assume that user did
    # not want to update the password and remove the two from the params hash
    def ignore_blank_password
      return if params[:account][:password].present? ||
                params[:account][:password_confirmation].present?

      params[:account].delete(:password)
      params[:account].delete(:password_confirmation)
    end
  end
end
