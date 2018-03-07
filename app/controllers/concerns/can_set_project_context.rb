# frozen_string_literal: true

# Define setter method for setting the instance variables needed to correctly
# display the project header and check permissions
module CanSetProjectContext
  extend ActiveSupport::Concern

  included do
    rescue_from CanCan::AccessDenied do |exception|
      can_can_access_denied(exception)
    end
  end

  private

  def authorize_project_access
    authorize! :access, @project
  end

  def can_can_access_denied(exception)
    return unless exception.action == :access
    flash.now.alert = exception.message
    render 'errors/not_found', layout: 'application', status: 403
  end

  # Find and set project. Raise 404 if project does not exist
  def set_project
    @project = Project.find(profile_handle, profile_slug)
  end

  def profile_handle
    params[:profile_handle]
  end

  def profile_slug
    params[:project_slug]
  end
end
