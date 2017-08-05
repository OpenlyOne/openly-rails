# frozen_string_literal: true

# Base class for all app controllers
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_action :configure_permitted_parameters, if: :devise_controller?

  # override sign in redirect (Devise)
  def after_sign_in_path_for(resource)
    resource.user
  end

  protected

  # rubocop:disable Metrics/MethodLength
  def configure_permitted_parameters
    # Specify permitted parameters for sign up. This is necessary since we want
    # to allow nested attributes for user.
    # See: https://github.com/plataformatec/devise#strong-parameters
    devise_parameter_sanitizer.permit(:sign_up) do |account_params|
      account_params.permit(
        {
          user_attributes: [
            :name,
            { handle_attributes: [:identifier] }
          ]
        },
        :email, :password, :password_confirmation
      )
    end
  end
  # rubocop:enable Metrics/MethodLength
end
