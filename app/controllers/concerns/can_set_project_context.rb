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
    render 'projects/access_unauthorized', layout: 'application', status: 403
  end

  # Find and set project. Raise 404 if project does not exist
  def set_project
    set_project_by_handle_and_slug!
  end

  # Find and set project within the scope. Raise 404 if project does not exist
  # rubocop:disable Style/AccessorMethodName
  def set_project_by_handle_and_slug!(scope: Project)
    @project = scope.find_by_handle_and_slug!(profile_handle, profile_slug)
  end
  # rubocop:enable Style/AccessorMethodName

  # Find and set project where setup has been completed. Raise 404 if project
  # does not exist / is not complete
  def set_project_where_setup_is_complete
    set_project_by_handle_and_slug!(scope: Project.where_setup_is_complete)
  end

  def profile_handle
    params[:profile_handle]
  end

  def profile_slug
    params[:project_slug]
  end
end
