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

  def configure_permitted_parameters
    # Specify permitted parameters for sign up. This is necessary since we want
    # to allow nested attributes for user.
    # See: https://github.com/plataformatec/devise#strong-parameters
    devise_parameter_sanitizer.permit(:sign_up) do |account_params|
      account_params.permit(
        {
          user_attributes: %i[handle name]
        },
        :email, :password, :password_confirmation
      )
    end
  end

  # Redirect to the specified redirect location and set flash success message
  # rubocop:disable Metrics/MethodLength
  def redirect_with_success_to(redirect_location, options = {})
    resource_name = options[:resource] || controller_name.singularize.humanize
    default_inflected_action_name =
      case request.params[:action].to_s
      when 'create'
        'created'
      when 'update'
        'updated'
      when 'destroy'
        'deleted'
      end
    inflected_action_name = I18n.t action_name,
                                   scope: %i[actioncontroller actions],
                                   default: default_inflected_action_name
    flash[:notice] = "#{resource_name} successfully #{inflected_action_name}."
    redirect_to redirect_location
  end
  # rubocop:enable Metrics/MethodLength

  # Override the request format to prevent Rails from implying the format from
  # the URL. This is necessary because file names can end in .json or. xml or
  # other endings that are normally parsed by Rails.
  def set_default_request_format
    request.format = :html unless params[:format]
  end
end
