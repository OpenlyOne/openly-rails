# frozen_string_literal: true

# Base class for all app controllers
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_default_request_format

  # override sign in redirect (Devise)
  def after_sign_in_path_for(resource)
    stored_location_for(resource) || url_for(resource.user)
  end

  # Get the current user
  def current_user
    current_account.try(:user)
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

  # Override the request format to prevent Rails from implying the format from
  # the URL. This is necessary because file names can end in .json or. xml or
  # other endings that are normally parsed by Rails.
  def set_default_request_format
    request.format = :html unless params[:format]
  end
end
