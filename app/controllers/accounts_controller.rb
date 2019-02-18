# frozen_string_literal: true

# Devise-overwrite for editing, updating, and deleting accounts
class AccountsController < Devise::RegistrationsController
  protected

  # If you have extra params to permit, append them to the sanitizer.
  def account_update_params
    params.require(:account)
          .permit(:current_password, :password, :password_confirmation)
  end
end
