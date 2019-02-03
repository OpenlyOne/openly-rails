# frozen_string_literal: true

# Base class for all app controllers
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_default_request_format
  before_action :store_account_location!, if: :storable_location?

  after_action :track_action

  # override sign in redirect (Devise)
  def after_sign_in_path_for(resource)
    location = stored_location_for(resource) || profile_path(resource.user)

    # Redirect to profile page if stored location is root path
    return profile_path(resource.user) if location.eql?('/')

    location
  end

  # Get the current user
  def current_user
    current_account.try(:user)
  end

  # Lograge: Append information
  # Credits: https://github.com/ankane/production_rails
  def append_info_to_payload(payload)
    super
    payload[:request_id] = request.uuid
    payload[:user_id] = current_user.id if current_user
  end

  protected

  def authenticate_admin
    authenticate_account!
    authorize! :manage, :admin_panel
  end

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
      when 'create'   then 'created'
      when 'update'   then 'updated'
      when 'destroy'  then 'deleted'
      end
    inflected_action_name = I18n.t action_name,
                                   scope: %i[actioncontroller actions],
                                   default: default_inflected_action_name
    flash[:notice] = options[:notice] ||
                     "#{resource_name} successfully #{inflected_action_name}."
    redirect_to redirect_location
  end
  # rubocop:enable Metrics/MethodLength

  # Override the request format to prevent Rails from implying the format from
  # the URL. This is necessary because file names can end in .json or. xml or
  # other endings that are normally parsed by Rails.
  def set_default_request_format
    request.format = :html unless params[:format]
  end

  # Return true if the location is storable.
  # Its important that the location is NOT stored if:
  # - The request method is not GET (non idempotent)
  # - The request is handled by a Devise controller such as
  #   Devise::SessionsController as that could cause an infinite redirect loop.
  # - The request is an Ajax request as this can lead to very unexpected
  #   behavior
  def storable_location?
    request.get? &&
      is_navigational_format? &&
      !devise_controller? &&
      !request.xhr?
  end

  # Store the current path for the current user/account to allow redirect after
  # login
  def store_account_location!
    store_location_for(:account, request.fullpath)
  end

  # Track the page action
  def track_action
    ahoy.track "#{params[:controller]}##{params[:action]}",
               request.path_parameters
  end
end
