# frozen_string_literal: true

# Controller for project folders
class FoldersController < Abstract::FoldersController
  private

  def authorize_action
    authorize! :show, :file_in_branch, @project
  end

  def can_can_access_denied(exception)
    super || redirect_to(project_path, alert: exception.message)
  end

  def link_path_prefix
    'profile_project_'
  end

  def path_parameters
    [@project.owner, @project]
  end

  def project_path
    profile_project_path(@project.owner, @project)
  end

  def require_authentication?
    true
  end

  def set_user_can_commit_changes
    @user_can_commit_changes = can?(:new, :revision, @project)
  end

  # We don't need to set an object
  def set_object; end

  def set_branch
    @branch = @master_branch
  end
end
