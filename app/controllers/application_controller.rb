# frozen_string_literal: true

# Base class for all app controllers
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    # Specify permitted parameters for sign up. This is necessary since we want
    # to allow nested attributes for user.
    # See: https://github.com/plataformatec/devise#strong-parameters
    devise_parameter_sanitizer.permit(:sign_up) do |account_params|
      account_params.permit(
        { user_attributes: [:name] },
        :email, :password, :password_confirmation
      )
    end
  end
end
